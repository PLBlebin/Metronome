import 'package:flutter/material.dart';
import '../../notifiers/metronome_notifier.dart';
import '../widgets/beat_display.dart';
import '../widgets/bpm_display.dart';
import '../widgets/bpm_slider.dart';
import '../widgets/bpm_step_buttons.dart';
import '../widgets/tap_tempo_button.dart';
import '../widgets/time_signature_row.dart';
import '../widgets/sound_panel.dart';
import '../widgets/subdivision_panel.dart';
import '../widgets/preset_panel.dart';
import '../widgets/practice_mode_panel.dart';

class MetronomeScreen extends StatefulWidget {
  final MetronomeNotifier notifier;

  const MetronomeScreen({super.key, required this.notifier});

  @override
  State<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends State<MetronomeScreen> {
  MetronomeNotifier get _n => widget.notifier;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _n,
      builder: (context, _) {
        final s = _n.state;
        return Scaffold(
          appBar: AppBar(
            title: const Text('节拍器'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // BPM 大数字
                BpmDisplay(bpm: s.bpm, onChanged: _n.setBpm),
                const SizedBox(height: 8),
                // 节拍指示点
                BeatDisplay(
                  beatStream: _n.beatStream,
                  beatsPerMeasure: s.beatsPerMeasure,
                ),
                const SizedBox(height: 16),
                // 开始/停止
                FilledButton.icon(
                  onPressed: _n.togglePlay,
                  icon: Icon(s.isRunning ? Icons.stop : Icons.play_arrow),
                  label: Text(s.isRunning ? '停止' : '开始'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(160, 52),
                  ),
                ),
                const SizedBox(height: 16),
                // Tap Tempo
                TapTempoButton(onBpmChanged: _n.setBpm),
                const SizedBox(height: 16),
                // BPM 滑块
                BpmSlider(bpm: s.bpm, onChanged: _n.setBpm),
                // 步进按钮
                BpmStepButtons(bpm: s.bpm, onChanged: _n.setBpm),
                const SizedBox(height: 16),
                // 拍号
                TimeSignatureRow(
                  beatsPerMeasure: s.beatsPerMeasure,
                  noteValue: s.noteValue,
                  onBeatsChanged: _n.setBeatsPerMeasure,
                  onNoteValueChanged: _n.setNoteValue,
                ),
                const Divider(height: 24),
                // 音色 + 音量
                SoundPanel(
                  soundType: s.soundType,
                  volume: s.volume,
                  onSoundTypeChanged: _n.setSoundType,
                  onVolumeChanged: _n.setVolume,
                ),
                const Divider(height: 24),
                // 细分
                SubdivisionPanel(
                  subdivision: s.subdivision,
                  onChanged: _n.setSubdivision,
                ),
                const Divider(height: 24),
                // 预设
                PresetPanel(
                  presets: _n.presets,
                  onSave: _n.savePreset,
                  onLoad: _n.loadPreset,
                  onDelete: _n.deletePreset,
                ),
                const Divider(height: 24),
                // 练习模式
                PracticeModePanel(
                  state: s,
                  onRampEnabledChanged: _n.setRampEnabled,
                  onRampEveryNBarsChanged: _n.setRampEveryNBars,
                  onRampByBpmChanged: _n.setRampByBpm,
                  onMuteEnabledChanged: _n.setMuteEnabled,
                  onMuteEveryNBarsChanged: _n.setMuteEveryNBars,
                  onMuteDurationBarsChanged: _n.setMuteDurationBars,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
