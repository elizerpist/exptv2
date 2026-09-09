import json, math, sys
from pathlib import Path
root=Path(sys.argv[1])
data=json.loads((root/'artifact/build/dashboard_profile_complete_response.json').read_text())
results={}
failures=[]
def check(ok, label):
    if not ok: failures.append(label)
for label, left_key, right_key, no_slowdown in [
    ('year_empty_vs_populated','B_year_month_rail_populated','C_year_month_rail_empty',False),
    ('month_empty_vs_populated','D_month_day_rail_94','E_month_day_rail_empty',False),
    ('first_vs_tenth_fling','I_first_fling','J_tenth_fling',True),
]:
    left,right=data[left_key],data[right_key]
    export=data['dashboard_profile_comparisons'][label]
    for key in ['rail_target_index','rail_settle_index','semantic_sequence']:
        check(left[key]==right[key],label+' '+key)
    ltime,rtime=left['motion_duration_micros'],right['motion_duration_micros']
    tolerance=max(32000,math.floor(ltime*.15+.5))
    check(rtime<=ltime+tolerance if no_slowdown else abs(rtime-ltime)<=tolerance,label+' duration')
    deltas={}
    for source_key, export_key in [
        ('95th_percentile_frame_build_time_millis','frame_build_p95_delta_percent'),
        ('95th_percentile_frame_rasterizer_time_millis','frame_raster_p95_delta_percent'),
    ]:
        a,b=left[source_key],right[source_key]
        delta=0 if a==0 else (b-a)/a*100
        check(math.isclose(delta,export[export_key],rel_tol=1e-10,abs_tol=1e-10),label+' '+export_key)
        deltas[export_key]=delta
    check(export['target_equal'] is True and export['settle_equal'] is True,label+' export equality')
    lf,rf=left['rail_flight'],right['rail_flight']
    velocity={}
    for key in ['drag_end_velocity','ballistic_input_velocity']:
        a,b=lf[key],rf[key]
        denom=max(abs(a),abs(b))
        difference=0 if denom==0 else abs(a-b)/denom
        check(difference<=.02,label+' '+key)
        velocity[key]=difference
    pixel_diff=abs(lf['total_pixel_distance']-rf['total_pixel_distance'])
    logical_diff=abs(lf['logical_delta']-rf['logical_delta'])
    check(pixel_diff<=lf['item_extent']/2,label+' pixels')
    check(logical_diff<=1,label+' logical delta')
    results[label]={
        'first_motion_micros':ltime,'second_motion_micros':rtime,'tolerance_micros':tolerance,
        'target_equal':True,'settle_equal':True,'semantic_sequence_equal':left['semantic_sequence']==right['semantic_sequence'],
        'relative_velocity_differences':velocity,'physical_endpoint_difference_pixels':pixel_diff,
        'logical_endpoint_difference':logical_diff,**deltas,
    }
scene_keys=['textLayoutMisses','criticalCacheMisses','readySceneIncomplete','activeWindowPartialPublish','stagingObjectRendered','railCriticalLookupMiss','visiblePayloadWithoutDrawable','visiblePayloadWithoutPaint','railCanonicalCenterMismatch','freshVerticalGestureRejected']
for key in data['dashboard_profile_suite_completion']['scenario_report_keys']:
    window=data[key]['physical_rail_report']['sceneWindow']
    for counter in scene_keys:check(window[counter]==0,key+' '+counter)
report={'validation':'passed' if not failures else 'rejected','checks_owner':'independent review of committed _expectEquivalentMotion/_expectEquivalentRailFlight/_p95Comparison and scene counters','comparisons':results,'all_scene_counters_zero':not any(any(c in f for c in scene_keys) for f in failures),'failures':failures}
(root/'comparison-validation-result.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
if failures:raise SystemExit(1)
