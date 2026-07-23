import 'dart:async';
import 'dart:io';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kzdownloader/core/download/providers/download_provider.dart';
import 'package:kzdownloader/core/download/providers/playlist_provider.dart';
import 'package:kzdownloader/core/services/audio_player_service.dart';
import 'package:kzdownloader/l10n/arb/app_localizations.dart';
import 'package:kzdownloader/models/download_task.dart';
import 'package:kzdownloader/models/playlist.dart';
import 'package:kzdownloader/views/chat/widgets/audio_widgets.dart';
import 'package:kzdownloader/views/chat/widgets/header.dart';
import 'package:kzdownloader/views/chat/widgets/headers/category_header.dart';
import 'package:kzdownloader/views/chat/widgets/music_playlist_detail_pane.dart';
import 'package:kzdownloader/views/chat/widgets/music_table_row.dart';
import 'package:kzdownloader/views/widgets/confirm_dialog.dart';
import 'package:ultimate_flutter_icons/ficon.dart';
import 'package:ultimate_flutter_icons/icons/ri.dart';
import 'package:kzdownloader/views/chat/screens/sort_options.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kzdownloader/core/utils/m3u8_utils.dart';

class MusicScreen extends ConsumerStatefulWidget {
  final String searchQuery;
  final SortOption selectedSortOption;
  final Function(String) onSearchChanged;
  final Function(SortOption) onSortChanged;
  final Function(DownloadTask) onTaskSelected;
  final VoidCallback? onAddUrl;

  const MusicScreen({
    super.key,
    required this.searchQuery,
    required this.selectedSortOption,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onTaskSelected,
    this.onAddUrl,
  });

  @override
  ConsumerState<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends ConsumerState<MusicScreen> {
  Playlist? _selectedPlaylist;

  void _showCreatePlaylistDialog() {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    showConfirmDialog(context,
        title: l10n.newPlaylistTitle,
        content: l10n.playlistNameEditHint, onConfirm: () {
      if (controller.text.isNotEmpty) {
        ref.read(playlistListProvider.notifier).createPlaylist(controller.text);
      }
    },
        confirmText: l10n.btnCreate,
        cancelText: l10n.btnCancel,
        icon: Icons.playlist_add,
        iconColor: Colors.blueAccent,
        hasInput: true,
        inputController: controller);
  }

  Future<void> _importM3U8() async {
    final l10n = AppLocalizations.of(context)!;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    final entries = M3U8Utils.parseM3U8(content);

    if (entries.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noMatchingTracks)),
      );
      return;
    }

    // Match entries against existing download tasks by original URL.
    final allTasks = await ref.read(downloadListProvider.future);
    final entryUrls = entries.map((e) => e.url).toSet();

    final localTasks = allTasks
        .where((t) => entryUrls.contains(t.url) && t.downloadStatus.isSuccess)
        .toList();
    final localUrls = localTasks.map((t) => t.url).toSet();
    final toDownloadUrls =
        entries.where((e) => !localUrls.contains(e.url)).toList();

    if (localTasks.isEmpty && toDownloadUrls.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noMatchingTracks)),
      );
      return;
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ImportM3U8ConfirmDialog(
        localCount: localTasks.length,
        toDownloadEntries: toDownloadUrls,
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    // Derive playlist name from filename (strip .m3u8 extension)
    final filename = result.files.single.name;
    final playlistName = filename.toLowerCase().endsWith('.m3u8')
        ? filename.substring(0, filename.length - 5)
        : filename;

    // createPlaylist returns the saved object with its DB-assigned id
    final newPlaylist = await ref
        .read(playlistListProvider.notifier)
        .createPlaylist(playlistName);

    if (localTasks.isNotEmpty) {
      await ref
          .read(playlistListProvider.notifier)
          .addTasksToPlaylist(newPlaylist.id, localTasks);
    }

    if (toDownloadUrls.isNotEmpty) {
      final playlistId = newPlaylist.id;
      final pendingUrls = toDownloadUrls.map((e) => e.url).toSet();

      for (final entry in toDownloadUrls) {
        await ref.read(downloadListProvider.notifier).addTask(
              entry.url,
              'yt-dlp',
              isAudio: true,
              category: TaskCategory.music,
            );
      }

      StreamSubscription? sub;
      sub = ref.read(dbServiceProvider).watchTasks().listen((tasks) async {
        final justCompleted = tasks.where((t) =>
            pendingUrls.contains(t.url) &&
            t.downloadStatus.isSuccess &&
            t.filePath != null);

        for (final task in justCompleted) {
          if (!pendingUrls.contains(task.url)) continue;
          pendingUrls.remove(task.url);
          await ref
              .read(playlistListProvider.notifier)
              .addTasksToPlaylist(playlistId, [task]);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      AppLocalizations.of(context)!.importDownloadComplete)),
            );
          }
        }

        if (pendingUrls.isEmpty) await sub?.cancel();
      });
    }

    if (!mounted) return;
    setState(() => _selectedPlaylist = newPlaylist);

    final snackMsg = toDownloadUrls.isEmpty
        ? l10n.importSuccessAllLocal(localTasks.length)
        : l10n.importSuccessWithDownloads(
            localTasks.length, toDownloadUrls.length);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(snackMsg),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Widget _buildPlaylistSectionHeader(
      AppLocalizations l10n, ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.playlist_play, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              l10n.playlistSection,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _importM3U8,
              icon: FIcon(RI.RiUploadLine,
                  size: 14, color: colorScheme.onSurfaceVariant),
              label: Text(
                l10n.importM3u8,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Divider(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloadListAsync = ref.watch(downloadListProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final playlists = ref.watch(playlistListProvider);
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        downloadListAsync.when(
          data: (allTasks) {
            final tasks =
                allTasks.where((e) => !e.isPlaylistContainer).toList();
            final musicTasks = _sortTasks(
                filterMusicTasks(tasks, widget.searchQuery),
                widget.selectedSortOption);

            // Different layout for macOS vs Windows/Linux
            if (Platform.isMacOS) {
              // macOS: CategoryHeader inside left column
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          CategoryHeader(
                              category: TaskCategory.music,
                              onSearchChanged: widget.onSearchChanged,
                              onTaskAdded: widget.onTaskSelected,
                              onAddUrl: widget.onAddUrl),
                          Expanded(
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(24, 24, 24, 0),
                                  child: _buildPlaylistSectionHeader(
                                      l10n, colorScheme),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 8),
                                  child: SizedBox(
                                    height: 110,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      clipBehavior: Clip.none,
                                      children: [
                                        ...playlists.map((playlist) => Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 16),
                                              child: PlaylistCard(
                                                playlist: playlist,
                                                onTap: () => setState(() =>
                                                    _selectedPlaylist =
                                                        playlist),
                                                gradientColors: [
                                                  Color(
                                                      playlist.gradientColor1),
                                                  Color(
                                                      playlist.gradientColor2),
                                                ],
                                              ),
                                            )),
                                        buildNewMixCard(
                                          context,
                                          colorScheme.primary,
                                          onTap: _showCreatePlaylistDialog,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 24),
                                        child: SectionHeader(
                                            title: l10n.musicSection,
                                            icon: Icons.music_note),
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 16,
                                        child: SizedBox(
                                          width: 155,
                                          child: CustomDropdown<SortOption>(
                                            hintText: getSortOptionLabel(
                                                widget.selectedSortOption,
                                                l10n),
                                            items:
                                                getAvailableSortOptionsForCategory(
                                                    TaskCategory.music),
                                            closedHeaderPadding:
                                                const EdgeInsets.only(
                                                    top: 4,
                                                    bottom: 4,
                                                    right: 4),
                                            expandedHeaderPadding:
                                                const EdgeInsets.only(
                                                    top: 4,
                                                    bottom: 4,
                                                    right: 4),
                                            initialItem:
                                                widget.selectedSortOption,
                                            decoration:
                                                CustomDropdownDecoration(
                                              closedFillColor:
                                                  Colors.transparent,
                                              expandedFillColor:
                                                  colorScheme.surface,
                                              closedBorderRadius:
                                                  BorderRadius.circular(8),
                                              expandedBorderRadius:
                                                  BorderRadius.circular(8),
                                              expandedBorder: Border.all(
                                                color: colorScheme.primary
                                                    .withValues(alpha: 0.15),
                                                width: 1,
                                              ),
                                            ),
                                            listItemBuilder: (context, item,
                                                isSelected, onItemSelect) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6),
                                                child: Text(
                                                  getSortOptionLabel(
                                                      item, l10n),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.w400,
                                                    color: isSelected
                                                        ? colorScheme.primary
                                                        : colorScheme.onSurface,
                                                  ),
                                                ),
                                              );
                                            },
                                            headerBuilder: (context,
                                                selectedItem, isOpen) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      getSortOptionIcon(
                                                          selectedItem),
                                                      size: 18,
                                                      color:
                                                          colorScheme.primary,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      getSortOptionLabel(
                                                          selectedItem, l10n),
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: colorScheme
                                                            .onSurface,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            onChanged: (value) {
                                              if (value != null) {
                                                widget.onSortChanged(value);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildMusicTableHeader(colorScheme, l10n),
                                musicTasks.isEmpty
                                    ? _buildEmptyState(colorScheme, l10n)
                                    : _buildMusicList(musicTasks, colorScheme),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildPlaylistDetailPane()
                  ]);
            } else {
              // Windows/Linux: CategoryHeader on top, panes below it
              return Column(
                children: [
                  CategoryHeader(
                      category: TaskCategory.music,
                      onSearchChanged: widget.onSearchChanged,
                      onTaskAdded: widget.onTaskSelected,
                      onAddUrl: widget.onAddUrl),
                  Expanded(
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(24, 24, 24, 0),
                                  child: _buildPlaylistSectionHeader(
                                      l10n, colorScheme),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 8),
                                  child: SizedBox(
                                    height: 110,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      clipBehavior: Clip.none,
                                      children: [
                                        ...playlists.map((playlist) => Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 16),
                                              child: PlaylistCard(
                                                playlist: playlist,
                                                onTap: () => setState(() =>
                                                    _selectedPlaylist =
                                                        playlist),
                                                gradientColors: [
                                                  Color(
                                                      playlist.gradientColor1),
                                                  Color(
                                                      playlist.gradientColor2),
                                                ],
                                              ),
                                            )),
                                        buildNewMixCard(
                                          context,
                                          colorScheme.primary,
                                          onTap: _showCreatePlaylistDialog,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32),
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 24),
                                        child: SectionHeader(
                                            title: l10n.musicSection,
                                            icon: Icons.music_note),
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 16,
                                        child: SizedBox(
                                          width: 156,
                                          child: CustomDropdown<SortOption>(
                                            hintText: getSortOptionLabel(
                                                widget.selectedSortOption,
                                                l10n),
                                            items:
                                                getAvailableSortOptionsForCategory(
                                                    TaskCategory.music),
                                            closedHeaderPadding:
                                                const EdgeInsets.only(
                                                    top: 4,
                                                    bottom: 4,
                                                    right: 4),
                                            expandedHeaderPadding:
                                                const EdgeInsets.only(
                                                    top: 4,
                                                    bottom: 4,
                                                    right: 4),
                                            initialItem:
                                                widget.selectedSortOption,
                                            decoration:
                                                CustomDropdownDecoration(
                                              closedFillColor:
                                                  Colors.transparent,
                                              expandedFillColor:
                                                  colorScheme.surface,
                                              closedBorderRadius:
                                                  BorderRadius.circular(8),
                                              expandedBorderRadius:
                                                  BorderRadius.circular(8),
                                              expandedBorder: Border.all(
                                                color: colorScheme.primary
                                                    .withValues(alpha: 0.15),
                                                width: 1,
                                              ),
                                            ),
                                            listItemBuilder: (context, item,
                                                isSelected, onItemSelect) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6),
                                                child: Text(
                                                  getSortOptionLabel(
                                                      item, l10n),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.w400,
                                                    color: isSelected
                                                        ? colorScheme.primary
                                                        : colorScheme.onSurface,
                                                  ),
                                                ),
                                              );
                                            },
                                            headerBuilder: (context,
                                                selectedItem, isOpen) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      getSortOptionIcon(
                                                          selectedItem),
                                                      size: 18,
                                                      color:
                                                          colorScheme.primary,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      getSortOptionLabel(
                                                          selectedItem, l10n),
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: colorScheme
                                                            .onSurface,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            onChanged: (value) {
                                              if (value != null) {
                                                widget.onSortChanged(value);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildMusicTableHeader(colorScheme, l10n),
                                musicTasks.isEmpty
                                    ? _buildEmptyState(colorScheme, l10n)
                                    : _buildMusicList(musicTasks, colorScheme),
                              ],
                            ),
                          ),
                          _buildPlaylistDetailPane()
                        ]),
                  ),
                ],
              );
            }
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('${l10n.errorPrefix}$err')),
        ),
      ],
    );
  }

  Widget _buildMusicTableHeader(
      ColorScheme colorScheme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              '#',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              l10n.titleColumn,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              l10n.artistColumn,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              l10n.albumColumn,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              l10n.durationColumn,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: Text(
              l10n.formatColumn,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FIcon(
              RI.RiMusicLine,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noMusicFound,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicList(
      List<DownloadTask> musicTasks, ColorScheme colorScheme) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: musicTasks.length,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final task = musicTasks[index];
        final audioState = ref.watch(audioStateProvider);
        final isPlaying =
            audioState.currentTaskId == task.id && audioState.isPlaying;

        return MusicTableRow(
          index: index + 1,
          task: task,
          isPlaying: isPlaying,
          colorScheme: colorScheme,
          onTap: () {
            ref.read(audioStateProvider.notifier).playAudio(
                  task.filePath!,
                  thumbnail: task.thumbnail,
                  title: task.title,
                  channel: task.channelName,
                  taskId: task.id,
                );
          },
          onDelete: () {
            ref.read(downloadListProvider.notifier).deleteTask(task.id);
          },
        );
      },
    );
  }

  Widget _buildPlaylistDetailPane() {
    return AnimatedContainer(
      width: _selectedPlaylist != null
          ? MediaQuery.of(context).size.width * 0.3 < 550
              ? MediaQuery.of(context).size.width * 0.3
              : 550
          : 0,
      curve: Curves.decelerate,
      duration: const Duration(milliseconds: 300),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _selectedPlaylist != null
              ? PlaylistDetailPane(
                  playlist: _selectedPlaylist!,
                  onClose: () => setState(() => _selectedPlaylist = null),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  List<DownloadTask> _sortTasks(List<DownloadTask> tasks, SortOption option) {
    final sortedTasks = List<DownloadTask>.from(tasks);

    switch (option) {
      case SortOption.recent:
        sortedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.downloaded:
        sortedTasks.sort((a, b) {
          final aCompleted = a.downloadStatus.isSuccess ? 1 : 0;
          final bCompleted = b.downloadStatus.isSuccess ? 1 : 0;
          if (aCompleted != bCompleted) {
            return bCompleted.compareTo(aCompleted);
          }
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
      case SortOption.summaries:
        sortedTasks.sort((a, b) {
          final aHasSummary =
              (a.summary != null && a.summary!.trim().isNotEmpty) ? 1 : 0;
          final bHasSummary =
              (b.summary != null && b.summary!.trim().isNotEmpty) ? 1 : 0;
          if (aHasSummary != bHasSummary) {
            return bHasSummary.compareTo(aHasSummary);
          }
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
      case SortOption.playlists:
        sortedTasks.sort((a, b) {
          final aIsPlaylist = a.isPlaylistContainer ? 1 : 0;
          final bIsPlaylist = b.isPlaylistContainer ? 1 : 0;
          if (aIsPlaylist != bIsPlaylist) {
            return bIsPlaylist.compareTo(aIsPlaylist);
          }
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
    }

    return sortedTasks;
  }
}
