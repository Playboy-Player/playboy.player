import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class MPlayer extends StatefulWidget {
  const MPlayer({super.key, required this.title});
  final String title;

  @override
  MPlayerState createState() => MPlayerState();
}

class MPlayerState extends State<MPlayer> {
  late final Player playboy;
  late final VideoController controller;
  late Uint8List image;
  bool imageLoaded = false;

  bool menuExpanded = false;
  double seekingPos = 0;
  bool seeking = false;

  bool silent = false;
  double volume = 100;

  @override
  void initState() {
    playboy = Player();
    controller = VideoController(playboy);
    super.initState();
  }

  @override
  void dispose() {
    playboy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    late final colorScheme = Theme.of(context).colorScheme;
    late final backgroundColor = Color.alphaBlend(
        colorScheme.primary.withOpacity(0.08), colorScheme.surface);
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildTitlebar(backgroundColor),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: _buildPlayer(colorScheme),
                  ),
                ),
                menuExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: SizedBox(
                          width: 300,
                          child: _buildSidePanel(colorScheme, backgroundColor),
                        ))
                    : const SizedBox(),
              ],
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width - 40,
            height: 25,
            child: Row(
              children: [
                StreamBuilder(
                  stream: playboy.stream.position,
                  builder:
                      (BuildContext context, AsyncSnapshot<Duration> snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                          '${snapshot.data!.inSeconds ~/ 3600}:${(snapshot.data!.inSeconds % 3600 ~/ 60).toString().padLeft(2, '0')}:${(snapshot.data!.inSeconds % 60).toString().padLeft(2, '0')}');
                    } else {
                      return const Text('0:00:00');
                    }
                  },
                ),
                Expanded(child: _buildSeekbar()),
                StreamBuilder(
                  stream: playboy.stream.duration,
                  builder:
                      (BuildContext context, AsyncSnapshot<Duration> snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                          '${snapshot.data!.inSeconds ~/ 3600}:${(snapshot.data!.inSeconds % 3600 ~/ 60).toString().padLeft(2, '0')}:${(snapshot.data!.inSeconds % 60).toString().padLeft(2, '0')}');
                    } else {
                      return const Text('0:00:00');
                    }
                  },
                ),
              ],
            ),
          ),
          SizedBox(
            height: 60,
            child: _buildControlbar(colorScheme),
          ),
          const SizedBox(
            height: 10,
          )
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTitlebar(Color backgroundColor) {
    return AppBar(
      toolbarHeight: 50,
      backgroundColor: backgroundColor,
      scrolledUnderElevation: 0,
      title: Text(widget.title),
      actions: [
        IconButton(
            tooltip: 'open file',
            onPressed: () async {
              var res = await FilePicker.platform
                  .pickFiles(type: FileType.media, lockParentWindow: true);
              if (res != null) {
                String link = res.files.single.path!;
                playboy.stop();
                playboy.open(Media(link));
              }
            },
            icon: const Icon(Icons.insert_drive_file_outlined)),
        IconButton(
          tooltip: 'open/close menu',
          isSelected: menuExpanded,
          icon: const Icon(Icons.view_sidebar),
          selectedIcon: const Icon(Icons.view_sidebar_outlined),
          onPressed: () {
            setState(() {
              menuExpanded = !menuExpanded;
            });
          },
        ),
        const SizedBox(
          width: 10,
        )
      ],
    );
  }

  Widget _buildPlayer(ColorScheme colorScheme) {
    return ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(25)),
        child: Container(
          color: Colors.black,
          child: Center(
            child: Video(
              controller: controller,
              controls: NoVideoControls,
              subtitleViewConfiguration:
                  const SubtitleViewConfiguration(visible: false),
            ),
          ),
        ));
  }

  Widget _buildSeekbar() {
    return SliderTheme(
      data: SliderThemeData(
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      child: StreamBuilder(
        stream: playboy.stream.position,
        builder: (context, snapshot) {
          double pos = 0;
          if (snapshot.hasData) {
            pos = snapshot.data!.inMilliseconds.toDouble();
          }
          return Slider(
            max: playboy.state.duration.inMilliseconds.toDouble(),
            value: seeking
                ? seekingPos
                : min(pos, playboy.state.duration.inMilliseconds.toDouble()),
            onChanged: (value) {
              setState(() {
                seekingPos = value;
              });
            },
            onChangeStart: (value) {
              setState(() {
                seeking = true;
              });
            },
            onChangeEnd: (value) {
              playboy
                  .seek(Duration(milliseconds: value.toInt()))
                  .then((value) => {
                        setState(() {
                          seeking = false;
                        })
                      });
            },
          );
        },
      ),
    );
  }

  Widget _buildSidePanel(ColorScheme colorScheme, Color backgroundColor) {
    return ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(25)),
        child: DefaultTabController(
          initialIndex: 0,
          length: 2,
          child: Scaffold(
            backgroundColor: colorScheme.background,
            appBar: const TabBar(
              tabs: <Widget>[
                Tab(
                  icon: Icon(Icons.input),
                ),
                Tab(
                  icon: Icon(Icons.output),
                ),
              ],
            ),
            body: TabBarView(
              children: <Widget>[
                Center(
                  child: imageLoaded
                      ? Image.memory(image)
                      : const Center(
                          child: Text('image input is empty'),
                        ),
                ),
                const Center(
                  child: Text("image output is empty"),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildControlbar(ColorScheme colorScheme) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Expanded(
        child: Row(
          children: [
            const SizedBox(
              width: 16,
            ),
            IconButton(
                onPressed: () {
                  setState(() {
                    if (silent) {
                      silent = false;
                      playboy.setVolume(volume);
                    } else {
                      silent = true;
                      playboy.setVolume(0);
                    }
                  });
                },
                icon: Icon(silent ? Icons.volume_off : Icons.volume_up)),
            SizedBox(
              width: 100,
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: colorScheme.secondaryContainer,
                  thumbColor: colorScheme.onSecondaryContainer,
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  max: 100,
                  value: volume,
                  onChanged: (value) {
                    setState(() {
                      volume = value;
                      if (!silent) {
                        playboy.setVolume(value);
                      }
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(
        width: 10,
      ),
      IconButton(
          tooltip: 'repeat',
          onPressed: () {
            if (playboy.state.playlistMode == PlaylistMode.single) {
              playboy.setPlaylistMode(PlaylistMode.none);
            } else {
              playboy.setPlaylistMode(PlaylistMode.single);
            }
            setState(() {});
          },
          icon: playboy.state.playlistMode == PlaylistMode.single
              ? const Icon(Icons.repeat_one_on)
              : const Icon(Icons.repeat_one)),
      const SizedBox(
        width: 10,
      ),
      IconButton.filledTonal(
        tooltip: 'restart',
        icon: const Icon(Icons.settings_backup_restore),
        onPressed: () {
          playboy.seek(const Duration(milliseconds: 0));
        },
      ),
      const SizedBox(
        width: 10,
      ),
      IconButton.filled(
        tooltip: 'play or pause',
        style: IconButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        iconSize: 40,
        onPressed: () {
          setState(() {
            playboy.playOrPause();
          });
        },
        icon: Icon(
          playboy.state.playing
              ? Icons.pause_circle_outline
              : Icons.play_arrow_outlined,
        ),
      ),
      const SizedBox(
        width: 10,
      ),
      IconButton.filledTonal(
        tooltip: 'stop',
        icon: const Icon(Icons.stop),
        onPressed: () {
          playboy.stop();
        },
      ),
      const SizedBox(
        width: 10,
      ),
      IconButton(
          tooltip: 'screenshot',
          onPressed: () async {
            var res = await playboy.screenshot();
            if (res != null) {
              image = res;
              setState(() {
                imageLoaded = true;
              });
            }
          },
          icon: const Icon(Icons.camera_alt)),
      const SizedBox(
        width: 10,
      ),
      Expanded(
          child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 100,
            child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: colorScheme.secondaryContainer,
                  thumbColor: colorScheme.onSecondaryContainer,
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  max: 4,
                  value: playboy.state.rate,
                  onChanged: (value) {
                    setState(() {
                      playboy.setRate(value);
                    });
                  },
                )),
          ),
          IconButton(
              onPressed: () {
                setState(() {
                  playboy.setRate(1);
                });
              },
              icon: Icon(
                  playboy.state.rate == 1 ? Icons.flash_off : Icons.flash_on)),
          const SizedBox(
            width: 16,
          ),
        ],
      )),
    ]);
  }
}
