import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/file_system.dart';
import '../providers/library_provider.dart';
import '../providers/cloud_sync_provider.dart';
import 'canvas_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, library, child) {
        bool isSelection = library.isSelectionMode;
        
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          drawer: isSelection ? null : _buildDrawer(context, library),
          appBar: AppBar(
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 0,
            iconTheme: Theme.of(context).iconTheme,
            leading: isSelection 
              ? IconButton(icon: const Icon(Icons.close), onPressed: () => library.clearSelection()) 
              : null,
            title: isSelection 
              ? Text('${library.selectedIds.length} Selected') 
              : _buildSearchField(library),
            actions: isSelection 
              ? _buildSelectionActions(context, library)
              : [
                  Consumer<CloudSyncProvider>(
                    builder: (context, syncProvider, child) {
                      return Row(
                        children: [
                          IconButton(
                            icon: syncProvider.isSyncing 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                                : const Icon(Icons.cloud_sync, color: Colors.blueAccent),
                            tooltip: 'Sync',
                            onPressed: syncProvider.isSyncing ? null : () => syncProvider.syncToCloud(),
                          ),
                          const SizedBox(width: 8),
                          _buildUserAccountAction(context, syncProvider),
                          const SizedBox(width: 16),
                        ],
                      );
                    }
                  ),
                ],
          ),
          body: _buildBody(context, library),
          floatingActionButton: (isSelection || library.viewMode == LibraryViewMode.trash) ? null : _buildMultiActionFAB(context, library),
        );
      }
    );
  }

  Widget _buildSearchField(LibraryProvider library) {
    return Container(
      height: 40,
      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: TextField(
        onChanged: (val) => library.setSearchQuery(val),
        decoration: const InputDecoration(
          hintText: 'Search Notes...',
          prefixIcon: Icon(Icons.search, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, LibraryProvider library) {
    List<FileSystemNode> items;
    if (library.viewMode == LibraryViewMode.recent) {
       items = library.recentNodes;
    } else if (library.viewMode == LibraryViewMode.trash) {
       items = library.trashNodes;
    } else {
       items = library.currentFolder.children.where((n) => !n.isDeleted).toList();
    }

    if (library.lastSearchQuery.isNotEmpty) {
       items = items.where((n) => n.title.toLowerCase().contains(library.lastSearchQuery.toLowerCase())).toList();
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              library.viewMode == LibraryViewMode.trash ? Icons.delete_outline : Icons.search_off, 
              size: 60, 
              color: Colors.grey.withOpacity(0.3)
            ),
            const SizedBox(height: 16),
            Text(
              library.viewMode == LibraryViewMode.trash ? 'Trash is empty' : 'No matches found',
              style: const TextStyle(color: Colors.black45, fontSize: 16)
            ),
          ],
        )
      );
    }
    return Column(
      children: [
        if (library.viewMode == LibraryViewMode.all && library.breadcrumbs.isNotEmpty)
          _buildBreadcrumbsRow(context, library),
        Expanded(child: _buildGridView(context, library, items)),
      ],
    );
  }

  Widget _buildBreadcrumbsRow(BuildContext context, LibraryProvider library) {
     return Container(
       height: 36,
       padding: const EdgeInsets.symmetric(horizontal: 16),
       child: ListView.separated(
         scrollDirection: Axis.horizontal,
         itemCount: library.breadcrumbs.length + 1,
         separatorBuilder: (_, __) => const Icon(Icons.chevron_right, size: 14),
         itemBuilder: (context, i) {
            String title = i == 0 ? "Root" : library.breadcrumbs[i-1].title;
            return TextButton(
              onPressed: () => library.navigateToBreadcrumb(i - 1),
              child: Text(title, style: const TextStyle(fontSize: 12)),
            );
         },
       ),
     );
  }

  Widget _buildGridView(BuildContext context, LibraryProvider library, List<FileSystemNode> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth > 900) {
          crossAxisCount = 8;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 6;
        }
        
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16, 
            mainAxisSpacing: 20, 
            childAspectRatio: 0.68
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final node = items[index];
            bool isSelected = library.selectedIds.contains(node.id);
            
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (library.isSelectionMode) {
                  library.toggleSelection(node.id);
                } else if (node.isDeleted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Restore to view this note")));
                } else if (node is NoteNode) {
                  library.markOpened(node.id);
                  library.addTab(node);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CanvasScreen()));
                } else if (node is FolderNode) {
                  library.enterFolder(node);
                }
              },
              onLongPress: () => library.toggleSelection(node.id),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _NotebookCoverWidget(
                        title: node.title,
                        color: (node is NoteNode) ? Color(node.note.coverColorValue) : Colors.grey.shade400,
                        isSelected: library.isSelectionMode ? isSelected : false,
                        isFolder: node is FolderNode,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    node.title, 
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
                ],
              ),
            );
          },
        );
      }
    );
  }

  List<Widget> _buildSelectionActions(BuildContext context, LibraryProvider library) {
    if (library.viewMode == LibraryViewMode.trash) {
       return [
          IconButton(icon: const Icon(Icons.restore_from_trash), onPressed: () => library.restoreSelected()),
          IconButton(icon: const Icon(Icons.delete_forever), onPressed: () => library.deleteSelected()),
       ];
    }
    return [
      if (library.selectedIds.length == 1) ...[
          IconButton(
            icon: const Icon(Icons.edit_note), 
            onPressed: () => _showRenameDialog(context, library, library.selectedIds.first)
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined), 
            onPressed: () => _showColorPicker(context, library, library.selectedIds.first)
          ),
      ],
      IconButton(icon: const Icon(Icons.drive_file_move_outlined), onPressed: () {}),
      IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => library.deleteSelected()),
    ];
  }

  void _showRenameDialog(BuildContext context, LibraryProvider library, String id) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Item'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'New name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              library.renameNode(id, controller.text);
              library.clearSelection();
              Navigator.pop(ctx);
            },
            child: const Text('Rename'),
          ),
        ],
      )
    );
  }

  void _showColorPicker(BuildContext context, LibraryProvider library, String id) {
     final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.brown, Colors.teal, Colors.black];
     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         title: const Text('Change Cover Color'),
         content: Wrap(
           spacing: 12, runSpacing: 12,
           children: colors.map((c) => InkWell(
             onTap: () {
               library.updateNoteCover(id, c.value);
               library.clearSelection();
               Navigator.pop(ctx);
             },
             child: CircleAvatar(backgroundColor: c, radius: 20),
           )).toList(),
         ),
       )
     );
  }

  Widget _buildDrawer(BuildContext context, LibraryProvider library) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blueAccent),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Note Station', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text('Professional Hub', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.library_books),
            title: const Text('My Library'),
            selected: library.viewMode == LibraryViewMode.all,
            onTap: () { library.setViewMode(LibraryViewMode.all); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Recently Opened'),
            selected: library.viewMode == LibraryViewMode.recent,
            onTap: () { library.setViewMode(LibraryViewMode.recent); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Recycle Bin'),
            selected: library.viewMode == LibraryViewMode.trash,
            onTap: () { library.setViewMode(LibraryViewMode.trash); Navigator.pop(context); },
          ),
        ],
      ),
    );
  }

  Widget _buildMultiActionFAB(BuildContext context, LibraryProvider library) {
    return FloatingActionButton(
      onPressed: () => _showCreateMenu(context, library),
      backgroundColor: Colors.blueAccent,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _showCreateMenu(BuildContext context, LibraryProvider library) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.note_add, color: Colors.white)),
              title: const Text('New Note'),
              subtitle: const Text('Create a blank canvas or template'),
              onTap: () {
                Navigator.pop(ctx);
                _showNewNoteDialog(context, library);
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.create_new_folder, color: Colors.white)),
              title: const Text('New Folder'),
              subtitle: const Text('Organize your documents'),
              onTap: () {
                Navigator.pop(ctx);
                _showNewFolderDialog(context, library);
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.purpleAccent, child: Icon(Icons.image, color: Colors.white)),
              title: const Text('Import Image'),
              subtitle: const Text('Create note from photo'),
              onTap: () {
                 Navigator.pop(ctx);
                 _importImage(context, library);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importImage(BuildContext context, LibraryProvider library) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.single.bytes != null) {
       library.createNewNoteWithImage(result.files.single.name, result.files.single.bytes!);
    }
  }

  Widget _buildUserAccountAction(BuildContext context, CloudSyncProvider syncProvider) {
     return InkWell(
       onTap: () => _showAccountDialog(context, syncProvider),
       child: CircleAvatar(
         radius: 16,
         backgroundColor: syncProvider.isLoggedIn ? Colors.blueAccent : Colors.grey.shade400,
         child: syncProvider.isLoggedIn 
            ? Text(syncProvider.userName[0], style: const TextStyle(color: Colors.white, fontSize: 12))
            : const Icon(Icons.person, color: Colors.white, size: 20),
       ),
     );
  }

  void _showAccountDialog(BuildContext context, CloudSyncProvider syncProvider) {
     showDialog(
       context: context,
       builder: (ctx) => StatefulBuilder(
         builder: (context, setDialogState) {
           return AlertDialog(
             title: const Text('Cloud Account'),
             content: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 if (syncProvider.isLoggedIn) ...[
                    const CircleAvatar(radius: 30, backgroundColor: Colors.blueAccent, child: Icon(Icons.person, size: 40, color: Colors.white)),
                    const SizedBox(height: 12),
                    Text(syncProvider.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Auto Backup to Cloud'),
                              Switch(
                                value: syncProvider.autoSync,
                                onChanged: (val) {
                                  setDialogState(() {
                                    syncProvider.toggleAutoSync(val);
                                  });
                                }
                              )
                            ],
                          ),
                          if (syncProvider.lastSyncTime != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Last backed up: ${syncProvider.lastSyncTime!.month}/${syncProvider.lastSyncTime!.day} ${syncProvider.lastSyncTime!.hour}:${syncProvider.lastSyncTime!.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            )
                        ],
                      ),
                    ),
                 ] else ...[
                    const Icon(Icons.cloud_off, size: 50, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('Login to sync your notes across devices'),
                 ]
               ],
             ),
             actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                if (!syncProvider.isLoggedIn)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text('Google Login'),
                    onPressed: () { 
                      syncProvider.signInWithGoogle(context);
                      Navigator.pop(ctx);
                    },
                  )
                else ...[
                   if (!syncProvider.isSyncing)
                     ElevatedButton.icon(
                       icon: const Icon(Icons.backup),
                       label: const Text('Backup Now'),
                       onPressed: () { 
                         syncProvider.syncToCloud();
                         Navigator.pop(ctx);
                       },
                     ),
                   TextButton(
                     onPressed: () { syncProvider.logout(); Navigator.pop(ctx); },
                     child: const Text('Logout', style: TextStyle(color: Colors.red)),
                   ),
                ]
             ],
           );
         }
       )
     );
  }

  void _showNewNoteDialog(BuildContext context, LibraryProvider library) {
    final controller = TextEditingController();
    String selectedTemplate = 'blank';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Note Title')),
              const SizedBox(height: 20),
              const Text('Select Template', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                   ChoiceChip(
                     label: const Text('Blank'), 
                     selected: selectedTemplate == 'blank', 
                     onSelected: (_) => setDialogState(() => selectedTemplate = 'blank')
                   ),
                   ChoiceChip(
                     label: const Text('Grid'), 
                     selected: selectedTemplate == 'grid', 
                     onSelected: (_) => setDialogState(() => selectedTemplate = 'grid')
                   ),
                   ChoiceChip(
                     label: const Text('Lines'), 
                     selected: selectedTemplate == 'lines', 
                     onSelected: (_) => setDialogState(() => selectedTemplate = 'lines')
                   ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                library.createNewNote(controller.text.isEmpty ? "Untitled Note" : controller.text, selectedTemplate);
                Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewFolderDialog(BuildContext context, LibraryProvider library) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Folder Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              library.createNewFolder(controller.text.isEmpty ? "Untitled Folder" : controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      )
    );
  }
}

class _NotebookCoverWidget extends StatelessWidget {
  final String title;
  final Color color;
  final bool isSelected;
  final bool isFolder;
  const _NotebookCoverWidget({required this.title, required this.color, required this.isSelected, required this.isFolder});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
        boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4)],
        border: isSelected ? Border.all(color: Colors.blueAccent, width: 3) : null,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0, top: 0, bottom: 0, width: 10,
            child: Container(decoration: BoxDecoration(color: Colors.black.withOpacity(0.15))),
          ),
          Center(
            child: isFolder 
              ? const Icon(Icons.folder_shared, color: Colors.white, size: 28)
              : Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    title.isNotEmpty ? title.substring(0, 1).toUpperCase() : "?", 
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ),
          ),
          if (isSelected) const Positioned(top: 4, right: 4, child: Icon(Icons.check_circle, color: Colors.blueAccent, size: 18)),
        ],
      ),
    );
  }
}
