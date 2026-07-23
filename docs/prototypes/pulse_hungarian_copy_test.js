const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const htmlPath = path.join(__dirname, "pulse_engine_panel_mockup.html");
const html = fs.readFileSync(htmlPath, "utf8");
const staticCopy = html
  .replace(/<style\b[\s\S]*?<\/style>/gi, " ")
  .replace(/<script\b[\s\S]*?<\/script>/gi, " ")
  .replace(/<[^>]+>/g, " ")
  .replace(/\s+/g, " ");
const scriptCopy = (html.match(/<script\b[\s\S]*?<\/script>/gi) || []).join("\n");

const staticForeignTerms = [
  /\bUser score\b/i,
  /\bPulse decision flow\b/i,
  /\bBudget pressure\b/i,
  /\bCashflow pressure\b/i,
  /\bData quality\b/i,
  /\bEngine decision trace\b/i,
  /\bRaw metrics\b/i,
  /\bSignal builder\b/i,
  /\bStory builder\b/i,
  /\bHeader delivery\b/i,
  /\bPriority score\b/i,
  /\bSelection\b/i,
  /\bStory copy map\b/i,
  /\bTrigger\b/i,
  /\bSource\b/i,
  /\bTarget\b/i,
  /\bDomain\b/i,
  /\bFingerprint\b/i,
  /\bEligible\b/i,
  /\bReady\b/i,
  /\bWaiting\b/i,
  /\bSelected\b/i,
  /\bSuppressed\b/i,
  /\bForecast\b/i,
  /\bThreshold\b/i,
  /\bConfidence\b/i,
  /\bEvidence\b/i,
  /\bScore\b/i,
  /\bPriority\b/i
];

for (const term of staticForeignTerms) {
  assert.doesNotMatch(staticCopy, term, `látható angol vagy technikai felirat maradt: ${term}`);
}

const generatedForeignPhrases = [
  /<h3>1\. Recalculation<\/h3>/i,
  /<h3>2\. Eligibility gate<\/h3>/i,
  /<h3>3\. Story formation<\/h3>/i,
  /<h3>4\. Priority ledger<\/h3>/i,
  /<h3>5\. Header delivery \+ lifecycle<\/h3>/i,
  /<h3>6\. Story copy map<\/h3>/i,
  /<strong>Selected header source<\/strong>/i,
  /\bBudget \+ fixed load story\b/i,
  /\bUpcoming fixed-cost story\b/i,
  /\bRecovery story\b/i,
  /\bData quality story\b/i
];

for (const phrase of generatedForeignPhrases) {
  assert.doesNotMatch(scriptCopy, phrase, `dinamikus angol felirat maradt: ${phrase}`);
}

const dynamicForeignPhrases = [
  /\bForeground transaction change\b/i,
  /\bBackground transaction change\b/i,
  /\bMonth-end expense forecast\b/i,
  /\bMonthly category limit burn\b/i,
  /\bYearly category limit burn\b/i,
  /\bFixed cost load\b/i,
  /\bGhost income missing\b/i,
  /\bSavings goal forecast\b/i,
  /\bBalance buffer days\b/i,
  /\bUncategorized status\b/i,
  /\bMaterial money impact\b/i,
  /\bRelated evidence in the same story\b/i,
  /\bSelected for the one current header pulse\b/i,
  /\bNo source role\b/i,
  /\bCalculation view\b/i,
  /\btransparent tuning\b/i,
  /\bsource domain\b/i
];

for (const phrase of dynamicForeignPhrases) {
  assert.doesNotMatch(scriptCopy, phrase, "dinamikus angol felirat maradt: " + phrase);
}

assert.match(html, /allapotFelirat\(signal\.state\)/, "a belső állapotkódok magyar felirattal jelenjenek meg");
assert.match(html, /allapotFelirat\(candidate\.status\)/, "a jelölt állapotkódja magyar felirattal jelenjen meg");
assert.match(html, /jelCsoportFelirat\(domain\)/, "a belső jelcsoport-kód magyar felirattal jelenjen meg");
assert.match(html, /szerepModFelirat\(role\.mode\)/, "a belső mondatszerep-kód magyar felirattal jelenjen meg");
assert.doesNotMatch(html, /legacy-workspace|data-legacy-tab/, "a rejtett, idegen nyelvű régi felület nem maradhat a fájlban");

assert.match(html, /data-plain-language-flowchart/);
assert.match(html, /assets\/pulse-egyszeru-mukodes\.png/);

console.log("pulse_hungarian_copy_test: PASS");
