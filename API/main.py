import os
from typing import Optional
from dataclasses import dataclass, asdict
import requests
import json
import random
import zlib

from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

from google import genai
from google.genai import types, errors


THUMBS_DIR = "thumbs"
RECIPES_DIR = "recipes"
NUM_SUGGESTIONS = 2
EMPTY_RECIPE = {
    "recipeName": "",
    "description": "",
    "prepTime": "",
    "coolTime": "",
    "ingredients": [{"item": "", "quantity": ""}],
    "instructions": "",
}

gemini_client = genai.Client()

app = FastAPI()

os.makedirs(THUMBS_DIR, exist_ok=True)
os.makedirs(RECIPES_DIR, exist_ok=True)
app.mount("/thumbs", StaticFiles(directory=THUMBS_DIR), name="thumbs")
app.mount("/recipes", StaticFiles(directory=RECIPES_DIR), name="recipes")


def hash_filename(filename: str) -> str:
    return format(zlib.adler32(filename.encode("utf-8")) & 0xFFFFFFFF, "08x")


class DataModel(BaseModel):
    ingredients: list[str]


class Ingredients(BaseModel):
    japanese_name: str
    english_name: str


def get_recipes_names(ingredients: list[str]) -> list[dict[str, str]]:
    response = gemini_client.models.generate_content(
        model="gemini-2.5-flash",
        contents=f"Give me just the names of and a simple one line description of {NUM_SUGGESTIONS} japanese household recipes using the following ingredients: {', '.join(ingredients)}",
        config=types.GenerateContentConfig(
            thinking_config=types.ThinkingConfig(thinking_budget=0),
            response_mime_type="application/json",
            system_instruction=f"You will only ever use Japanese when replying.",
        ),
    )
    return json.loads(response.text)


def get_recipe_images(names: list[str]) -> None:
    images = []
    for name in names:
        response = gemini_client.models.generate_content(
            model="gemini-2.5-flash-image",
            contents=[f"An image of {name}"],
        )
        for part in response.candidates[0].content.parts:
            if part.inline_data is not None:
                image = Image.open(BytesIO(part.inline_data.data))
                image.save(os.path.join(THUMBS_DIR, f"{name}.jpg"), format="JPEG")


def get_recipe_detail(recipe_name: str) -> str | None:
    filename = hash_filename(recipe_name) + ".json"
    if os.path.isfile(os.path.join(RECIPES_DIR, filename)):
        print("Recipe exists in cache.")
        with open(os.path.join(RECIPES_DIR, filename)) as file:
            return json.load(file)

    try:
        response = gemini_client.models.generate_content(
            model="gemini-2.5-flash",
            contents=f"Give me a detailed recipe for {recipe_name}",
            config=types.GenerateContentConfig(
                thinking_config=types.ThinkingConfig(thinking_budget=0),
                response_mime_type="application/json",
                system_instruction=f"You will only ever use Japanese when replying.\
    The reply JSON should have the following keys:\
        recipeName: str,\
        description: str,\
        prepTime: str,\
        coolTime: str,\
        ingredients: list,\
        instructions: str\
    Additionally, ingredients is a list of dicts with the following keys:\
        item: str,\
        quantity: str",
            ),
        )
    except errors.APIError as e:
        return EMPTY_RECIPE
    else:
        json_data = json.loads(response.text)
        print(json_data)
        with open(os.path.join(RECIPES_DIR, filename), 'w') as file:
            json.dump(json_data, file, ensure_ascii=False, indent=4)
        return json_data


@app.post("/overview")
def overview(data: DataModel):
    recipe_overviews = []
    for overview in get_recipes_names(data.ingredients):
        values = list(overview.values())
        d = {}
        d["name"] = values[0]
        d["description"] = values[1]
        recipe_overviews.append(d)

    # get_recipe_images(
    #     [
    #         d["name"]
    #         for d in recipe_overviews
    #         if not os.path.isfile(os.path.join(THUMBS_DIR, f"{d['name']}.jpg"))
    #     ]
    # )
    return recipe_overviews


@app.get("/details/{recipe_name}")
def details(recipe_name: str):
    res = get_recipe_detail(recipe_name)
    return res
