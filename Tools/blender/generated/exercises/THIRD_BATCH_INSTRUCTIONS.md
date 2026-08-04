# Third Batch — 10 New Exercise Animations

Baked 3D muscle-animation loops generated with the `Tools/blender/exercises/_lib.py`
pipeline (see `Tools/blender/exercises/ANIMATION_HANDOFF.md` for how it works).
Each is a 4-second, seamlessly looping, muted `.mp4` showing the worked muscle(s)
highlighted in orange on the app's skin-head + muscle-body figure. Videos are in
`Breath - Relax & Stretch/Resources/Animations/` and wired to their exercise via
`Exercise.animationName` in `SeedData.json`.

Steps below are copied verbatim from `SeedData.json` — the source of truth the
app actually ships.

---

## 1. Neck Extension Stretch (Gentle Look-Up)
**Target:** Front Neck &nbsp;·&nbsp; **Animation:** `neck_extension_look_up.mp4`

1. Sit or stand tall with a long spine.
2. Slowly tilt your head back to look toward the ceiling until you feel a gentle stretch under your chin and throat.
3. Hold for 10-15 seconds, breathing normally.
4. Return your head to neutral slowly.
5. Repeat 2-3 times.

**Caution:** Move slowly, keep the stretch gentle, and stop immediately if you feel dizzy or lightheaded.

---

## 2. Chin Tuck (Forward Head Reset)
**Target:** Front Neck, Back Neck, Neck &nbsp;·&nbsp; **Animation:** `chin_tuck_forward_head_reset.mp4`

1. Sit or stand tall with your shoulders relaxed.
2. Gently draw your chin straight back, as if making a "double chin".
3. Keep your eyes level — don't look down.
4. Hold for 3-5 seconds, then release.
5. Repeat 10 times to reset a forward-head posture.

**Caution:** Move gently and stop if you feel dizziness or sharp pain.

---

## 3. Right Standing Side Bend
**Target:** Right Obliques &nbsp;·&nbsp; **Animation:** `right_standing_side_bend.mp4`

1. Stand with feet shoulder-width apart, right hand resting on your right hip.
2. Slide your left hand down the outside of your left leg as you bend sideways to the left.
3. Keep your hips facing forward and avoid twisting.
4. Hold for 15-20 seconds, feeling the stretch along your right side.
5. Return to upright slowly and repeat.

---

## 4. Standing Back Extension
**Target:** Left Abs, Right Abs, Lower Back &nbsp;·&nbsp; **Animation:** `standing_back_extension.mp4`

1. Stand with feet hip-width apart and place your hands on your lower back for support.
2. Gently arch backward, leading with your chest and looking slightly upward.
3. Move only as far as feels comfortable — this is a small, controlled motion.
4. Hold for 5-10 seconds.
5. Return to standing tall and repeat 5-6 times.

**Caution:** Keep the arch gentle and controlled. Avoid if you have osteoporosis or acute back pain.

---

## 5. Cobra Stretch (Prone Press-Up)
**Target:** Left Abs, Right Abs &nbsp;·&nbsp; **Animation:** `cobra_stretch_prone_press_up.mp4`

1. Lie face down with hands planted under your shoulders and legs extended, tops of feet on the mat.
2. Press through your hands to lift your chest off the floor, keeping your hips down and elbows softly bent.
3. Lift only as high as feels comfortable in your lower back.
4. Hold for 15-20 seconds, breathing steadily.
5. Lower back down slowly to release.

**Caution:** Stop if you feel sharp or radiating lower-back pain; keep hips grounded throughout.

*Note: the rig has no floor/prone pose, so the animation approximates this as a standing backward arch of the torso — the muscle highlight and timing still match the real exercise.*

---

## 6. Left Seated Spinal Twist
**Target:** Spinal Erectors, Lower Back, Left Obliques, Lower Spine &nbsp;·&nbsp; **Animation:** `left_seated_spinal_twist.mp4`

1. Sit cross-legged or on the edge of a chair with your spine tall.
2. Place your right hand behind you and your left hand on your right knee.
3. Inhale to lengthen your spine, then exhale and gently twist to the right.
4. Hold for 20 seconds, keeping both sit bones grounded.
5. Unwind slowly back to center.

---

## 7. Right Seated Spinal Twist
**Target:** Spinal Erectors, Lower Back, Right Obliques, Lower Spine &nbsp;·&nbsp; **Animation:** `right_seated_spinal_twist.mp4`

1. Sit cross-legged or on the edge of a chair with your spine tall.
2. Place your left hand behind you and your right hand on your left knee.
3. Inhale to lengthen your spine, then exhale and gently twist to the left.
4. Hold for 20 seconds, keeping both sit bones grounded.
5. Unwind slowly back to center.

---

## 8. Reverse Prayer Stretch
**Target:** Left Forearm, Right Forearm, Left Shoulder, Right Shoulder &nbsp;·&nbsp; **Animation:** `reverse_prayer_stretch.mp4`

1. Bring both hands behind your back, fingers pointing downward.
2. Rotate your wrists so your palms come together in a reverse prayer position, fingers pointing up your spine.
3. Gently lift your hands up your back as high as is comfortable.
4. Hold for 15-20 seconds, feeling the stretch through both wrists and shoulders.
5. Release your hands and shake them out.

**Caution:** Skip if this is uncomfortable on the wrists or shoulders; a partial version is fine.

---

## 9. Left Wall Bicep Stretch
**Target:** Left Biceps &nbsp;·&nbsp; **Animation:** `left_wall_bicep_stretch.mp4`

1. Stand side-on to a wall, an arm's length away.
2. Place your left palm flat on the wall behind you, fingers pointing back, arm straight.
3. Slowly rotate your torso away from the wall until you feel a stretch through the front of your left arm.
4. Hold for 15-20 seconds.
5. Rotate back to release and switch sides.

**Caution:** Keep the elbow straight but not locked hard, and stop if you feel elbow or shoulder pain.

---

## 10. Right Wall Bicep Stretch
**Target:** Right Biceps &nbsp;·&nbsp; **Animation:** `right_wall_bicep_stretch.mp4`

1. Stand side-on to a wall, an arm's length away.
2. Place your right palm flat on the wall behind you, fingers pointing back, arm straight.
3. Slowly rotate your torso away from the wall until you feel a stretch through the front of your right arm.
4. Hold for 15-20 seconds.
5. Rotate back to release and switch sides.

**Caution:** Keep the elbow straight but not locked hard, and stop if you feel elbow or shoulder pain.

---

## Pipeline notes for whoever authors the next batch

- Scripts: `Tools/blender/exercises/{neck_extension_look_up, chin_tuck_forward_head_reset,
  right_standing_side_bend, standing_back_extension, cobra_stretch_prone_press_up,
  left_seated_spinal_twist, right_seated_spinal_twist, reverse_prayer_stretch,
  left_wall_bicep_stretch, right_wall_bicep_stretch}.py`
- All 10 stayed within **already-validated bone-axis conventions** (head/spine/chest
  pitch ±local-X, side-bend ±local-Z, twist ±local-Y; arm swing-back/adduction from
  the clasped-hands script) — deliberately avoided the hip/thigh/shin bones, which
  have no proven pose-authoring convention yet and were flagged in
  `ANIMATION_HANDOFF.md` as the next open frontier.
- The twist exercises (#6/#7) are the first use of local-Y (long-axis twist) on the
  vertical bones. The numeric "peak bone tail world position" sanity check in
  `_lib.py`'s `run()` is **blind to twist** (a bone rotating about its own length
  axis barely moves its tail) — verify twist direction by eyeballing the rendered
  PNGs, not the log.
- All 10 exported valid glTF skins (`skins:1, anims:1` each) and rendered with no
  visible tearing at the checked poses.
