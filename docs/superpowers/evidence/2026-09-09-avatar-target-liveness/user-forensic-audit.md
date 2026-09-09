# Fluvi Avatar-only forensic audit — aa61242

## Verdict

`aa61242c4b933ad9d650361ae1014d67fd184186` is physically rejected for
Avatar correctness. Its smooth carousel motion is protected, but the candidate
must not be promoted as a correct Avatar milestone.

## Current evidence

- Drive document: `Fluvi logs avatar fling`
- Drive ID: `1FF1BnHJHOEygG3QhMeDfrehzjo0YzIztaGJfNTWZqNs`
- Session: `fluvi-1788938720595789`
- Build: `aa61242c4b933ad9d650361ae1014d67fd184186`
- Export size: `689397` bytes
- Export SHA-256: `dcab9c791ba80d09ad79f20ab01cb33ce8c07d366757c241428f76f3bc4183d3`
- Raw event copies: `2000`
- Unique sequences: `1025`
- Exact duplicate copies: `975`
- Conflicting duplicate payloads: `0`

## Deduplicated key counts

```json
{
  "AV|PREVIEW_REQUESTED": 34,
  "AV|PREVIEW_ACCEPTED": 17,
  "AV|PREVIEW_REJECTED": 18,
  "AVATAR_CANDIDATE_PENDING_RESOURCE": 18,
  "AV|LIVE_ROOT_MISS": 17,
  "AV|LIVE_ROOT_RESOURCE_DEFERRED": 18,
  "BUDGET_PROGRESS_IDENTITY_MISMATCH": 20,
  "AV|LOGBOX_TARGET_PAINTED": 17,
  "BUDGET_AVATAR_MOTION_SUMMARY": 7
}
```

## Flight outcomes

```json
[
  {
    "generation": 22,
    "requested": [
      3,
      2,
      1,
      0,
      8,
      7,
      6
    ],
    "accepted": [],
    "rejected": [
      {
        "target": 3,
        "reason": "coordinatorRejected"
      },
      {
        "target": 2,
        "reason": "coordinatorRejected"
      },
      {
        "target": 1,
        "reason": "coordinatorRejected"
      },
      {
        "target": 0,
        "reason": "coordinatorRejected"
      },
      {
        "target": 8,
        "reason": "coordinatorRejected"
      },
      {
        "target": 7,
        "reason": "coordinatorRejected"
      },
      {
        "target": 6,
        "reason": "coordinatorRejected"
      }
    ],
    "pending": [
      3,
      2,
      1,
      0,
      8,
      7,
      6
    ],
    "settled": [
      6
    ],
    "motion_summary": {
      "seq": "2432",
      "elapsedMicros": "51218372",
      "generation": "22",
      "origin": "userDrag",
      "terminalReason": "settled",
      "avatarSemanticCrossings": "7",
      "avatarPreviewPublishes": "7",
      "directSemanticCrossings": "2",
      "ballisticSemanticCrossings": "5",
      "directPreviewRequests": "2",
      "ballisticPreviewRequests": "5",
      "directPreviewAccepted": "0",
      "ballisticPreviewAccepted": "0",
      "directPreviewRejected": "2",
      "ballisticPreviewRejected": "4",
      "directMatchingLogBoxPaints": "0",
      "ballisticMatchingLogBoxPaints": "0",
      "retainedExactPaints": "0",
      "visibleExactPaints": "0",
      "paintAccountingState": "noAcceptedPaintExpected",
      "pendingPaintTargetHandle": "-",
      "pendingPaintPhase": "-",
      "stalePreviewCompletions": "0",
      "untrackedPreviewCompletions": "0",
      "latestSemanticTargetHandle": "-",
      "latestPaintedTargetHandle": "-",
      "latestRichPaintedTargetHandle": "-",
      "settleTargetHandle": "6",
      "rawScrollUpdates": "74",
      "avatarRailBuilds": "0",
      "frameTimingSamples": "14",
      "frameTimingDroppedSamples": "0",
      "frameTimingMissedFrames": "0",
      "frameTimingBuildP50Micros": "1290",
      "frameTimingBuildP95Micros": "2953",
      "frameTimingBuildMaxMicros": "2953",
      "frameTimingRasterP50Micros": "5490",
      "frameTimingRasterP95Micros": "13101",
      "frameTimingRasterMaxMicros": "13101",
      "frameTimingTotalSpanP50Micros": "8470",
      "frameTimingTotalSpanP95Micros": "14988",
      "frameTimingTotalSpanMaxMicros": "14988",
      "rawToSemanticP95Micros": "25879",
      "semanticToStoreP95Micros": "0",
      "storeToPaintP95Micros": "0",
      "acknowledgedFrameToRasterP95Micros": "0",
      "budgetProgressPainted": "1",
      "budgetProgressPaintToRasterP95Micros": "7134",
      "frameTimingDiagnostics": "true",
      "firstTickMicros": "12986",
      "interTickMinMicros": "17712",
      "interTickMedianMicros": "45851",
      "interTickP95Micros": "83324",
      "interTickMaxMicros": "83324",
      "longGapCount": "5",
      "duplicateTickCount": "0",
      "skippedSemanticIndexCount": "0",
      "acceptedLiveSnapshots": "0",
      "semanticFrameAccepted": "0",
      "richScenePainted": "0",
      "completeLivePublications": "0",
      "sameVsyncCoalescedTickCount": "0",
      "repositoryRequestsAtTicks": "0",
      "indexBuildsAtTicks": "0",
      "scenePreparesAtTicks": "0",
      "canonicalPersistenceCommitsAtTicks": "0",
      "canonicalFocusCommitsAtSettle": "0",
      "settleVisualDeltaCount": "0",
      "partitionRetainedFromPreviousTarget": "false",
      "controllerIdentity": "355009129",
      "scrollPositionIdentity": "813525896",
      "physicsCreationCount": "1",
      "headerPalettePath": "discretePreparedPreview",
      "source": "preparedCatalog"
    }
  },
  {
    "generation": 23,
    "requested": [
      5,
      4,
      3,
      2,
      1,
      0,
      8
    ],
    "accepted": [
      5,
      4,
      3,
      2,
      1
    ],
    "rejected": [
      {
        "target": 0,
        "reason": "coordinatorRejected"
      },
      {
        "target": 8,
        "reason": "coordinatorRejected"
      }
    ],
    "pending": [
      0,
      8
    ],
    "settled": [],
    "motion_summary": {
      "seq": "2772",
      "elapsedMicros": "53869596",
      "generation": "23",
      "origin": "userDrag",
      "terminalReason": "interruptedByNewPointer",
      "avatarSemanticCrossings": "7",
      "avatarPreviewPublishes": "7",
      "directSemanticCrossings": "2",
      "ballisticSemanticCrossings": "5",
      "directPreviewRequests": "2",
      "ballisticPreviewRequests": "5",
      "directPreviewAccepted": "2",
      "ballisticPreviewAccepted": "3",
      "directPreviewRejected": "0",
      "ballisticPreviewRejected": "1",
      "directMatchingLogBoxPaints": "2",
      "ballisticMatchingLogBoxPaints": "3",
      "retainedExactPaints": "0",
      "visibleExactPaints": "5",
      "paintAccountingState": "accounted",
      "pendingPaintTargetHandle": "-",
      "pendingPaintPhase": "-",
      "stalePreviewCompletions": "0",
      "untrackedPreviewCompletions": "0",
      "latestSemanticTargetHandle": "-",
      "latestPaintedTargetHandle": "1",
      "latestRichPaintedTargetHandle": "-",
      "settleTargetHandle": "-",
      "rawScrollUpdates": "50",
      "avatarRailBuilds": "0",
      "frameTimingSamples": "15",
      "frameTimingDroppedSamples": "0",
      "frameTimingMissedFrames": "6",
      "frameTimingBuildP50Micros": "2352",
      "frameTimingBuildP95Micros": "9082",
      "frameTimingBuildMaxMicros": "9082",
      "frameTimingRasterP50Micros": "8467",
      "frameTimingRasterP95Micros": "13754",
      "frameTimingRasterMaxMicros": "13754",
      "frameTimingTotalSpanP50Micros": "13878",
      "frameTimingTotalSpanP95Micros": "22379",
      "frameTimingTotalSpanMaxMicros": "22379",
      "rawToSemanticP95Micros": "16928",
      "semanticToStoreP95Micros": "1719",
      "storeToPaintP95Micros": "11015",
      "acknowledgedFrameToRasterP95Micros": "13873",
      "budgetProgressPainted": "5",
      "budgetProgressPaintToRasterP95Micros": "13873",
      "frameTimingDiagnostics": "true",
      "firstTickMicros": "15994",
      "interTickMinMicros": "20527",
      "interTickMedianMicros": "49893",
      "interTickP95Micros": "83403",
      "interTickMaxMicros": "83403",
      "longGapCount": "5",
      "duplicateTickCount": "0",
      "skippedSemanticIndexCount": "0",
      "acceptedLiveSnapshots": "5",
      "semanticFrameAccepted": "5",
      "richScenePainted": "0",
      "completeLivePublications": "5",
      "sameVsyncCoalescedTickCount": "0",
      "repositoryRequestsAtTicks": "0",
      "indexBuildsAtTicks": "0",
      "scenePreparesAtTicks": "0",
      "canonicalPersistenceCommitsAtTicks": "0",
      "canonicalFocusCommitsAtSettle": "0",
      "settleVisualDeltaCount": "0",
      "partitionRetainedFromPreviousTarget": "false",
      "controllerIdentity": "355009129",
      "scrollPositionIdentity": "813525896",
      "physicsCreationCount": "1",
      "headerPalettePath": "discretePreparedPreview",
      "source": "preparedCatalog"
    }
  },
  {
    "generation": 24,
    "requested": [
      7,
      6,
      5,
      4,
      3,
      2,
      1
    ],
    "accepted": [
      6,
      5,
      4,
      3,
      2,
      1
    ],
    "rejected": [
      {
        "target": 7,
        "reason": "coordinatorRejected"
      }
    ],
    "pending": [
      7
    ],
    "settled": [],
    "motion_summary": {
      "seq": "2965",
      "elapsedMicros": "54722691",
      "generation": "24",
      "origin": "userDrag",
      "terminalReason": "interruptedByNewPointer",
      "avatarSemanticCrossings": "7",
      "avatarPreviewPublishes": "7",
      "directSemanticCrossings": "2",
      "ballisticSemanticCrossings": "5",
      "directPreviewRequests": "2",
      "ballisticPreviewRequests": "5",
      "directPreviewAccepted": "1",
      "ballisticPreviewAccepted": "5",
      "directPreviewRejected": "1",
      "ballisticPreviewRejected": "0",
      "directMatchingLogBoxPaints": "1",
      "ballisticMatchingLogBoxPaints": "5",
      "retainedExactPaints": "0",
      "visibleExactPaints": "6",
      "paintAccountingState": "accounted",
      "pendingPaintTargetHandle": "-",
      "pendingPaintPhase": "-",
      "stalePreviewCompletions": "0",
      "untrackedPreviewCompletions": "0",
      "latestSemanticTargetHandle": "-",
      "latestPaintedTargetHandle": "1",
      "latestRichPaintedTargetHandle": "-",
      "settleTargetHandle": "-",
      "rawScrollUpdates": "56",
      "avatarRailBuilds": "0",
      "frameTimingSamples": "21",
      "frameTimingDroppedSamples": "0",
      "frameTimingMissedFrames": "2",
      "frameTimingBuildP50Micros": "1416",
      "frameTimingBuildP95Micros": "6420",
      "frameTimingBuildMaxMicros": "6537",
      "frameTimingRasterP50Micros": "6049",
      "frameTimingRasterP95Micros": "12777",
      "frameTimingRasterMaxMicros": "13749",
      "frameTimingTotalSpanP50Micros": "11042",
      "frameTimingTotalSpanP95Micros": "17773",
      "frameTimingTotalSpanMaxMicros": "20609",
      "rawToSemanticP95Micros": "17207",
      "semanticToStoreP95Micros": "1609",
      "storeToPaintP95Micros": "16858",
      "acknowledgedFrameToRasterP95Micros": "11042",
      "budgetProgressPainted": "6",
      "budgetProgressPaintToRasterP95Micros": "11042",
      "frameTimingDiagnostics": "true",
      "firstTickMicros": "15719",
      "interTickMinMicros": "23463",
      "interTickMedianMicros": "45722",
      "interTickP95Micros": "83470",
      "interTickMaxMicros": "83470",
      "longGapCount": "5",
      "duplicateTickCount": "0",
      "skippedSemanticIndexCount": "0",
      "acceptedLiveSnapshots": "6",
      "semanticFrameAccepted": "6",
      "richScenePainted": "0",
      "completeLivePublications": "6",
      "sameVsyncCoalescedTickCount": "0",
      "repositoryRequestsAtTicks": "0",
      "indexBuildsAtTicks": "0",
      "scenePreparesAtTicks": "0",
      "canonicalPersistenceCommitsAtTicks": "0",
      "canonicalFocusCommitsAtSettle": "0",
      "settleVisualDeltaCount": "0",
      "partitionRetainedFromPreviousTarget": "false",
      "controllerIdentity": "355009129",
      "scrollPositionIdentity": "813525896",
      "physicsCreationCount": "1",
      "headerPalettePath": "discretePreparedPreview",
      "source": "preparedCatalog"
    }
  },
  {
    "generation": 25,
    "requested": [
      0,
      8,
      7,
      6,
      5
    ],
    "accepted": [
      6,
      5
    ],
    "rejected": [
      {
        "target": 0,
        "reason": "coordinatorRejected"
      },
      {
        "target": 8,
        "reason": "coordinatorRejected"
      },
      {
        "target": 7,
        "reason": "coordinatorRejected"
      }
    ],
    "pending": [
      0,
      8,
      7
    ],
    "settled": [
      5
    ],
    "motion_summary": {
      "seq": "3064",
      "elapsedMicros": "55818745",
      "generation": "25",
      "origin": "userDrag",
      "terminalReason": "settled",
      "avatarSemanticCrossings": "5",
      "avatarPreviewPublishes": "5",
      "directSemanticCrossings": "1",
      "ballisticSemanticCrossings": "4",
      "directPreviewRequests": "1",
      "ballisticPreviewRequests": "4",
      "directPreviewAccepted": "0",
      "ballisticPreviewAccepted": "2",
      "directPreviewRejected": "1",
      "ballisticPreviewRejected": "2",
      "directMatchingLogBoxPaints": "0",
      "ballisticMatchingLogBoxPaints": "2",
      "retainedExactPaints": "0",
      "visibleExactPaints": "2",
      "paintAccountingState": "accounted",
      "pendingPaintTargetHandle": "-",
      "pendingPaintPhase": "-",
      "stalePreviewCompletions": "0",
      "untrackedPreviewCompletions": "0",
      "latestSemanticTargetHandle": "5",
      "latestPaintedTargetHandle": "5",
      "latestRichPaintedTargetHandle": "-",
      "settleTargetHandle": "5",
      "rawScrollUpdates": "75",
      "avatarRailBuilds": "0",
      "frameTimingSamples": "19",
      "frameTimingDroppedSamples": "0",
      "frameTimingMissedFrames": "1",
      "frameTimingBuildP50Micros": "1191",
      "frameTimingBuildP95Micros": "6168",
      "frameTimingBuildMaxMicros": "6168",
      "frameTimingRasterP50Micros": "4924",
      "frameTimingRasterP95Micros": "10450",
      "frameTimingRasterMaxMicros": "10450",
      "frameTimingTotalSpanP50Micros": "8243",
      "frameTimingTotalSpanP95Micros": "18881",
      "frameTimingTotalSpanMaxMicros": "18881",
      "rawToSemanticP95Micros": "28150",
      "semanticToStoreP95Micros": "1576",
      "storeToPaintP95Micros": "4556",
      "acknowledgedFrameToRasterP95Micros": "12937",
      "budgetProgressPainted": "2",
      "budgetProgressPaintToRasterP95Micros": "12937",
      "frameTimingDiagnostics": "true",
      "firstTickMicros": "25355",
      "interTickMinMicros": "49973",
      "interTickMedianMicros": "63497",
      "interTickP95Micros": "82931",
      "interTickMaxMicros": "82931",
      "longGapCount": "4",
      "duplicateTickCount": "0",
      "skippedSemanticIndexCount": "0",
      "acceptedLiveSnapshots": "2",
      "semanticFrameAccepted": "2",
      "richScenePainted": "0",
      "completeLivePublications": "2",
      "sameVsyncCoalescedTickCount": "0",
      "repositoryRequestsAtTicks": "0",
      "indexBuildsAtTicks": "0",
      "scenePreparesAtTicks": "0",
      "canonicalPersistenceCommitsAtTicks": "0",
      "canonicalFocusCommitsAtSettle": "0",
      "settleVisualDeltaCount": "0",
      "partitionRetainedFromPreviousTarget": "false",
      "controllerIdentity": "355009129",
      "scrollPositionIdentity": "813525896",
      "physicsCreationCount": "1",
      "headerPalettePath": "discretePreparedPreview",
      "source": "preparedCatalog"
    }
  },
  {
    "generation": 26,
    "requested": [
      4,
      3,
      2,
      1,
      0,
      8
    ],
    "accepted": [
      4,
      3,
      2,
      1
    ],
    "rejected": [
      {
        "target": 0,
        "reason": "coordinatorRejected"
      },
      {
        "target": 8,
        "reason": "coordinatorRejected"
      }
    ],
    "pending": [
      0,
      8
    ],
    "settled": [
      8
    ],
    "motion_summary": {
      "seq": "3244",
      "elapsedMicros": "57135630",
      "generation": "26",
      "origin": "userDrag",
      "terminalReason": "settled",
      "avatarSemanticCrossings": "6",
      "avatarPreviewPublishes": "6",
      "directSemanticCrossings": "1",
      "ballisticSemanticCrossings": "5",
      "directPreviewRequests": "1",
      "ballisticPreviewRequests": "5",
      "directPreviewAccepted": "1",
      "ballisticPreviewAccepted": "3",
      "directPreviewRejected": "0",
      "ballisticPreviewRejected": "1",
      "directMatchingLogBoxPaints": "1",
      "ballisticMatchingLogBoxPaints": "3",
      "retainedExactPaints": "0",
      "visibleExactPaints": "4",
      "paintAccountingState": "accounted",
      "pendingPaintTargetHandle": "-",
      "pendingPaintPhase": "-",
      "stalePreviewCompletions": "0",
      "untrackedPreviewCompletions": "0",
      "latestSemanticTargetHandle": "1",
      "latestPaintedTargetHandle": "1",
      "latestRichPaintedTargetHandle": "-",
      "settleTargetHandle": "8",
      "rawScrollUpdates": "71",
      "avatarRailBuilds": "0",
      "frameTimingSamples": "19",
      "frameTimingDroppedSamples": "0",
      "frameTimingMissedFrames": "1",
      "frameTimingBuildP50Micros": "1196",
      "frameTimingBuildP95Micros": "6216",
      "frameTimingBuildMaxMicros": "6216",
      "frameTimingRasterP50Micros": "6364",
      "frameTimingRasterP95Micros": "15164",
      "frameTimingRasterMaxMicros": "15164",
      "frameTimingTotalSpanP50Micros": "10402",
      "frameTimingTotalSpanP95Micros": "19729",
      "frameTimingTotalSpanMaxMicros": "19729",
      "rawToSemanticP95Micros": "33624",
      "semanticToStoreP95Micros": "1673",
      "storeToPaintP95Micros": "15830",
      "acknowledgedFrameToRasterP95Micros": "11344",
      "budgetProgressPainted": "4",
      "budgetProgressPaintToRasterP95Micros": "11344",
      "frameTimingDiagnostics": "true",
      "firstTickMicros": "17439",
      "interTickMinMicros": "32956",
      "interTickMedianMicros": "33827",
      "interTickP95Micros": "100223",
      "interTickMaxMicros": "100223",
      "longGapCount": "5",
      "duplicateTickCount": "0",
      "skippedSemanticIndexCount": "0",
      "acceptedLiveSnapshots": "4",
      "semanticFrameAccepted": "4",
      "richScenePainted": "0",
      "completeLivePublications": "4",
      "sameVsyncCoalescedTickCount": "0",
      "repositoryRequestsAtTicks": "0",
      "indexBuildsAtTicks": "0",
      "scenePreparesAtTicks": "0",
      "canonicalPersistenceCommitsAtTicks": "0",
      "canonicalFocusCommitsAtSettle": "0",
      "settleVisualDeltaCount": "0",
      "partitionRetainedFromPreviousTarget": "false",
      "controllerIdentity": "355009129",
      "scrollPositionIdentity": "813525896",
      "physicsCreationCount": "1",
      "headerPalettePath": "discretePreparedPreview",
      "source": "preparedCatalog"
    }
  },
  {
    "generation": 27,
    "requested": [
      7
    ],
    "accepted": [],
    "rejected": [],
    "pending": [
      7
    ],
    "settled": [
      7
    ],
    "motion_summary": {
      "seq": "3347",
      "elapsedMicros": "64993748",
      "generation": "27",
      "origin": "userDrag",
      "terminalReason": "settled",
      "avatarSemanticCrossings": "1",
      "avatarPreviewPublishes": "1",
      "directSemanticCrossings": "1",
      "ballisticSemanticCrossings": "0",
      "directPreviewRequests": "1",
      "ballisticPreviewRequests": "0",
      "directPreviewAccepted": "0",
      "ballisticPreviewAccepted": "0",
      "directPreviewRejected": "0",
      "ballisticPreviewRejected": "0",
      "directMatchingLogBoxPaints": "0",
      "ballisticMatchingLogBoxPaints": "0",
      "retainedExactPaints": "0",
      "visibleExactPaints": "0",
      "paintAccountingState": "noAcceptedPaintExpected",
      "pendingPaintTargetHandle": "-",
      "pendingPaintPhase": "-",
      "stalePreviewCompletions": "0",
      "untrackedPreviewCompletions": "0",
      "latestSemanticTargetHandle": "-",
      "latestPaintedTargetHandle": "-",
      "latestRichPaintedTargetHandle": "-",
      "settleTargetHandle": "7",
      "rawScrollUpdates": "114",
      "avatarRailBuilds": "0",
      "frameTimingSamples": "12",
      "frameTimingDroppedSamples": "0",
      "frameTimingMissedFrames": "0",
      "frameTimingBuildP50Micros": "1169",
      "frameTimingBuildP95Micros": "1677",
      "frameTimingBuildMaxMicros": "1677",
      "frameTimingRasterP50Micros": "3913",
      "frameTimingRasterP95Micros": "7020",
      "frameTimingRasterMaxMicros": "7020",
      "frameTimingTotalSpanP50Micros": "6615",
      "frameTimingTotalSpanP95Micros": "10525",
      "frameTimingTotalSpanMaxMicros": "10525",
      "rawToSemanticP95Micros": "4464",
      "semanticToStoreP95Micros": "0",
      "storeToPaintP95Micros": "0",
      "acknowledgedFrameToRasterP95Micros": "0",
      "budgetProgressPainted": "0",
      "budgetProgressPaintToRasterP95Micros": "0",
      "frameTimingDiagnostics": "true",
      "firstTickMicros": "31701",
      "interTickMinMicros": "0",
      "interTickMedianMicros": "0",
      "interTickP95Micros": "0",
      "interTickMaxMicros": "0",
      "longGapCount": "0",
      "duplicateTickCount": "0",
      "skippedSemanticIndexCount": "0",
      "acceptedLiveSnapshots": "0",
      "semanticFrameAccepted": "0",
      "richScenePainted": "0",
      "completeLivePublications": "0",
      "sameVsyncCoalescedTickCount": "0",
      "repositoryRequestsAtTicks": "0",
      "indexBuildsAtTicks": "0",
      "scenePreparesAtTicks": "0",
      "canonicalPersistenceCommitsAtTicks": "0",
      "canonicalFocusCommitsAtSettle": "0",
      "settleVisualDeltaCount": "0",
      "partitionRetainedFromPreviousTarget": "false",
      "controllerIdentity": "355009129",
      "scrollPositionIdentity": "813525896",
      "physicsCreationCount": "1",
      "headerPalettePath": "discretePreparedPreview",
      "source": "preparedCatalog"
    }
  }
]
```

## Root-cause classification

The gesture, carousel physics and prepared focus-membership derivation are
healthy. The failing boundary is the exact painter-readable Phase-A resource
bind for non-empty Avatar payloads.

Current source can report a broad resource bank as ready while the exact target
binder rejects the payload. When the exact-local hotset window is unavailable,
the request returns false without guaranteeing replacement preparation. The
latest candidate then waits for a resource completion that may never occur.

Empty payloads bypass the binder. This explains why a Time change can
temporarily appear to fix Avatar: the sparse day scope makes several category
targets empty, while the non-empty aggregate and endpoint categories continue
to fail.

The resulting authority split can contain:
- physical centered handle 7;
- transient visual/progress handle 1;
- canonical committed focus handle 5.

## CI/profile gap

The current K validator checks positive accepted/paint counts and that the last
paint matches the visible frame. It does not require final physical settle
target parity, zero unresolved pending candidates, canonical focus parity, or
non-empty final-target coverage.

The exact K artifact extracted from CI is included separately.

## Required repair

Use the existing `budgetAvatarPreview` cache lane to guarantee a bounded,
target-local exact resource transaction for the latest non-empty Avatar
candidate. Every request needs a terminal outcome. The physical final target,
selected target, focus, visible Query, Header, circle progress, LogBox and
canonical settled focus must become one identity.

Time production code is out of scope.
