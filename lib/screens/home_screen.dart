import 'package:flutter/material.dart';
import '../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<FridgeItem>> _allFridgeItemsFuture;
  List<FridgeItem> _displayedFridgeItems = [];
  final TextEditingController _searchController = TextEditingController();

  // Selection state
  Set<FridgeItem> _selectedFridgeItems = {};
  bool _selectionMode = false;

  List<Category> _categories = [];
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();

    _loadCategories();

    _allFridgeItemsFuture = _fetchDatabaseItems();
    _allFridgeItemsFuture.then((fridgeItems) {
      setState(() {
        _displayedFridgeItems = _filterAndSortFridgeItems(fridgeItems);
      });
    });

    _searchController.addListener(() {
      _allFridgeItemsFuture.then((fridgeItems) {
        setState(() {
          _displayedFridgeItems = _filterAndSortFridgeItems(fridgeItems);
        });
      });
    });
  }

  Future<void> _loadCategories() async {
    final cats = await DatabaseService.instance.getCategories();
    setState(() {
      _categories = cats;
      // Optional: select the first category or null
      _selectedCategory = null;
    });
  }

  Future<List<FridgeItem>> _fetchDatabaseItems() async {
    return await DatabaseService.instance.getFridgeItems();
  }

  List<FridgeItem> _filterAndSortFridgeItems(List<FridgeItem> fridgeItems) {
    final filteredByCategory = _selectedCategory == null
        ? fridgeItems
        : fridgeItems
              .where((item) => item.category.id == _selectedCategory!.id)
              .toList();

    final filteredBySearch = filteredByCategory
        .where(
          (t) => t.productName.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ),
        )
        .toList();

    filteredBySearch.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    return filteredBySearch;
  }

  void _deleteSelectedFridgeItems() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete ${_selectedFridgeItems.length} item(s)?"),
        content: Text("Are you sure you want to delete the selected item(s)?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _selectedFridgeItems.forEach(
        (fridgeItem) async =>
            await DatabaseService.instance.removeFridgeItem(fridgeItem.id),
      );
      _allFridgeItemsFuture = _fetchDatabaseItems();
      _allFridgeItemsFuture.then((fridgeItems) {
        setState(() {
          _displayedFridgeItems = _filterAndSortFridgeItems(fridgeItems);
          _selectedFridgeItems.clear();
          _selectionMode = false;
        });
      });
    }
  }

  void _confirmSelection() {
    // Example action
    print("Confirmed ${_selectedFridgeItems.length} fridgeItems");
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text("FridgeItems List")),
      body: Column(
        children: [
          // Toolbar row
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                DropdownButton<Category?>(
                  value: _selectedCategory,
                  hint: const Text("Select category"),
                  items: [
                    const DropdownMenuItem<Category?>(
                      value: null,
                      child: Text("All"),
                    ),
                    ..._categories.map(
                      (cat) => DropdownMenuItem<Category?>(
                        value: cat,
                        child: Text(cat.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      _allFridgeItemsFuture.then((fridgeItems) {
                        _displayedFridgeItems = _filterAndSortFridgeItems(
                          fridgeItems,
                        );
                      });
                    });
                  },
                ),
                const Spacer(),
                SizedBox(
                  width: screenWidth * 0.5,
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search...",
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: FutureBuilder<List<FridgeItem>>(
              future: _allFridgeItemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error loading fridge items"));
                } else {
                  if (_displayedFridgeItems.isEmpty) {
                    return const Center(child: Text("No fridgeItems found"));
                  }
                  return ListView.separated(
                    itemCount: _displayedFridgeItems.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: Colors.grey.shade300, height: 1),
                    itemBuilder: (context, index) {
                      final fridgeItem = _displayedFridgeItems[index];
                      final isSelected = _selectedFridgeItems.contains(
                        fridgeItem,
                      );

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          fridgeItem.productName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          fridgeItem.category.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Checkbox(
                              value: isSelected,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: (checked) {
                                setState(() {
                                  _selectionMode = true;
                                  if (checked == true) {
                                    _selectedFridgeItems.add(fridgeItem);
                                  } else {
                                    _selectedFridgeItems.remove(fridgeItem);
                                    if (_selectedFridgeItems.isEmpty) {
                                      _selectionMode = false;
                                    }
                                  }
                                });
                              },
                            ),
                            Text(
                              "You have ${fridgeItem.expiryDate} remaining",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          if (_selectionMode) {
                            setState(() {
                              if (isSelected) {
                                _selectedFridgeItems.remove(fridgeItem);
                                if (_selectedFridgeItems.isEmpty) {
                                  _selectionMode = false;
                                }
                              } else {
                                _selectedFridgeItems.add(fridgeItem);
                              }
                            });
                          } else {
                            // Normal tap behavior
                            print("Opening ${fridgeItem.productName}");
                          }
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Delete FAB first
          if (_selectionMode && _selectedFridgeItems.isNotEmpty)
            FloatingActionButton(
              onPressed: _deleteSelectedFridgeItems,
              backgroundColor: Color.fromRGBO(228, 0, 80, 1),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
          const SizedBox(height: 12),
          // Confirm FAB below
          FloatingActionButton(
            onPressed: _selectedFridgeItems.isNotEmpty
                ? _confirmSelection
                : null,
            backgroundColor: _selectedFridgeItems.isNotEmpty
                ? Color.fromRGBO(112, 176, 228, 1)
                : Colors.grey.shade400,
            child: const Icon(Icons.check, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
