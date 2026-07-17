import 'stats_render_frame.dart';
import 'stats_render_frame_worker_base.dart';

export 'stats_render_frame_worker_base.dart';

class IsolateStatsRenderFrameWorker implements StatsRenderFrameWorker {
  const IsolateStatsRenderFrameWorker();

  @override
  Future<StatsRenderFrame> build(StatsRenderFrameRequest request) =>
      Future<StatsRenderFrame>.value(request.buildSynchronously());
}
