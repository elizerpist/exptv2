import 'package:exptv2/features/stats/data/stats_render_frame.dart';
import 'package:exptv2/features/stats/data/stats_render_frame_worker.dart';

class TestImmediateStatsFrameWorker implements StatsRenderFrameWorker {
  const TestImmediateStatsFrameWorker();

  @override
  Future<StatsRenderFrame> build(StatsRenderFrameRequest request) {
    return Future<StatsRenderFrame>.value(request.buildSynchronously());
  }
}
