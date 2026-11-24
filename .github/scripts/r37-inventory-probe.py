from pathlib import Path
base=Path('android/app/src/main/kotlin/com/fluvi/app/lockscreen')
def replace(p,old,new):
 s=p.read_text(); assert s.count(old)==1,(p,old,s.count(old)); p.write_text(s.replace(old,new))
q=base/'KeyguardCardInspectionQueue.kt'
needle='    fun openingChildBefore(request: KeyguardCardInspectionRequest, windowId: Int, index: Int) {}\n'
replace(q,needle,'    fun r37InventoryObserved(request: KeyguardCardInspectionRequest, clean: Boolean, windowId: Int?) {}\n'+needle)
r=base/'KeyguardWindowSnapshotReader.kt'
needle='        val knownOwnAtInventory: (() -> KeyguardOwnOverlayIdentity?)? = null,\n'
replace(r,needle,needle+'        val r37InventoryObservedForTest: ((Boolean, Int?) -> Unit)? = null,\n')
needle='''        var activeRoot: AccessibilityNodeInfo? = null
'''
replace(r,needle,'''        request.r37InventoryObservedForTest?.let { observer ->
            val clean = freshnessBoundaryEstablished && KeyguardWindowSnapshotReaderPolicy.cleanOpeningInventory(
                true, metadata, observedOwn, request.attachGeneration, activeCandidate)
            runCatching { observer(clean, activeCandidate?.id) }
        }
'''+needle)
p=base/'FluviKeyguardCardService.kt'
needle='                knownOwnAtInventory = { knownOwnOverlayIdentity },\n'
replace(p,needle,needle+'                r37InventoryObservedForTest = if (inspectionProbeForTest == null) null else { clean, id -> inspectionProbeForTest?.r37InventoryObserved(request, clean, id) },\n')
