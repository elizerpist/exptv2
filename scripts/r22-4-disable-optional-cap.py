from pathlib import Path
p=Path("android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt")
s=p.read_text(); old="if (!otherOwner && ownedByThisLease >= 2) {"; new="if (false && !otherOwner && ownedByThisLease >= 2) {"
assert s.count(old)==1
p.write_text(s.replace(old,new))
