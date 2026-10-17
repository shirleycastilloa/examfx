$ErrorActionPreference = 'Stop'

$markdownPath = Join-Path (Get-Location) 'series65_original_practice_bank.md'
$htmlPath = Join-Path (Get-Location) 'index.html'
$utf8 = [System.Text.UTF8Encoding]::new($false)
$markdown = [System.IO.File]::ReadAllText($markdownPath, $utf8)

function Encode([string]$value) {
    if ($null -eq $value) { return '' }
    return [System.Net.WebUtility]::HtmlEncode($value.Trim())
}

$questionBlocks = [regex]::Matches($markdown, '(?ms)^### (Q\d+)\s*\r?\n\r?\n(.*?)(?=^### Q\d+\s*$|^---\s*$)')
$questions = [System.Collections.Generic.List[object]]::new()

foreach ($block in $questionBlocks) {
    $id = $block.Groups[1].Value
    $body = $block.Groups[2].Value.Trim()
    $answerMatch = [regex]::Match($body, '(?ms)\*\*Answer:\*\*\s*([A-D])\s*\r?\n\s*\*\*Explanation:\*\*\s*(.*)$')
    if (-not $answerMatch.Success) { continue }

    $content = $body.Substring(0, $answerMatch.Index).Trim()
    $lines = $content -split '\r?\n'
    $questionLines = [System.Collections.Generic.List[string]]::new()
    $options = [ordered]@{}
    foreach ($line in $lines) {
        $clean = $line.Trim()
        if ($clean -match '^([A-D])\.\s+(.*?)(?:\s+)?$') {
            $options[$Matches[1]] = $Matches[2].Trim()
        } elseif ($clean.Length -gt 0) {
            $questionLines.Add($clean)
        }
    }
    if ($options.Count -ne 4) { continue }

    $questionText = ($questionLines -join ' ')
    $explanation = ($answerMatch.Groups[2].Value -replace '\s+', ' ').Trim()
    $questions.Add([ordered]@{
        id = $id
        prompt = $questionText
        options = $options
        answer = $answerMatch.Groups[1].Value
        explanation = $explanation
    })
}

if ($questions.Count -ne 270) {
    throw "Expected 270 questions, parsed $($questions.Count)."
}

$json = $questions | ConvertTo-Json -Depth 5 -Compress
$title = 'Series 65 Original Practice Bank'
$generated = Get-Date -Format 'yyyy-MM-dd HH:mm'
$ownerName = 'Josu' + [char]0x00E9 + ' Nu' + [char]0x00F1 + 'ez'

$html = @'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>__TITLE__</title>
  <meta name="description" content="A standalone English Series 65 practice application with 270 original questions, answers, explanations, scoring, and review tools.">
  <style>
    :root { --ink:#172033; --muted:#667085; --line:#e6eaf0; --paper:#ffffff; --bg:#f5f7fb; --navy:#13213b; --blue:#2563eb; --blue-soft:#eaf1ff; --green:#16845b; --green-soft:#e8f7f0; --red:#c24141; --red-soft:#fff0f0; --gold:#b7791f; --shadow:0 18px 55px rgba(24,39,75,.10); }
    * { box-sizing:border-box; }
    body { margin:0; color:var(--ink); background:var(--bg); font-family:Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; line-height:1.55; }
    button, select { font:inherit; }
    .shell { max-width:1200px; margin:0 auto; padding:28px 20px 64px; }
    .hero { color:#fff; background:linear-gradient(135deg,#12213e 0%,#1c3d72 62%,#265eaa 100%); border-radius:24px; padding:34px 36px; box-shadow:var(--shadow); }
    .eyebrow { text-transform:uppercase; letter-spacing:.10em; font-size:1.08rem; font-weight:850; color:#d6e5ff; }
    h1 { margin:8px 0 10px; font-size:clamp(2rem,4vw,3.5rem); line-height:1.04; letter-spacing:-.04em; }
    .hero p { max-width:760px; margin:0; color:#dbe8ff; font-size:1.03rem; }
    .hero-note { margin-top:20px; font-size:.84rem; color:#b9d3ff; }
    .toolbar { display:flex; flex-wrap:wrap; align-items:center; gap:12px; margin:22px 0; }
    .toolbar label { color:var(--muted); font-size:.9rem; font-weight:700; }
    select, .input { background:var(--paper); color:var(--ink); border:1px solid var(--line); border-radius:12px; padding:10px 12px; outline:none; }
    select:focus, .input:focus { border-color:var(--blue); box-shadow:0 0 0 3px var(--blue-soft); }
    .layout { display:grid; grid-template-columns:minmax(0,1fr) 300px; gap:22px; align-items:start; }
    .card { background:var(--paper); border:1px solid var(--line); border-radius:20px; box-shadow:var(--shadow); }
    .quiz { padding:30px; }
    .side { padding:22px; position:sticky; top:18px; }
    .meta { display:flex; flex-wrap:wrap; justify-content:space-between; gap:10px; color:var(--muted); font-size:.86rem; font-weight:700; margin-bottom:18px; }
    .progress { height:9px; background:#edf0f5; border-radius:999px; overflow:hidden; margin-bottom:26px; }
    .progress > div { height:100%; width:0; background:linear-gradient(90deg,#2563eb,#58a6ff); transition:width .25s ease; }
    .question { font-size:clamp(1.15rem,2vw,1.45rem); font-weight:780; letter-spacing:-.02em; margin:0 0 22px; }
    .options { display:grid; gap:12px; }
    .option { width:100%; text-align:left; border:1px solid var(--line); background:#fbfcfe; border-radius:14px; padding:15px 16px; color:var(--ink); cursor:pointer; transition:.18s ease; }
    .option:hover { border-color:#8fb3f6; background:#f7faff; transform:translateY(-1px); }
    .option.selected { border-color:var(--blue); background:var(--blue-soft); }
    .option.correct { border-color:var(--green); background:var(--green-soft); }
    .option.incorrect { border-color:var(--red); background:var(--red-soft); }
    .letter { display:inline-grid; place-items:center; width:29px; height:29px; margin-right:10px; border-radius:9px; background:#e9edf5; color:#344054; font-weight:800; }
    .selected .letter { background:var(--blue); color:#fff; }
    .correct .letter { background:var(--green); color:#fff; }
    .incorrect .letter { background:var(--red); color:#fff; }
    .feedback { display:none; margin-top:22px; padding:18px; border-radius:14px; border-left:4px solid var(--blue); background:#f7faff; }
    .feedback.show { display:block; }
    .feedback strong { display:block; margin-bottom:5px; }
    .feedback.correct { border-color:var(--green); background:var(--green-soft); }
    .feedback.incorrect { border-color:var(--red); background:var(--red-soft); }
    .actions { display:flex; flex-wrap:wrap; gap:10px; margin-top:26px; }
    .btn { border:0; border-radius:12px; padding:11px 16px; font-weight:800; cursor:pointer; transition:.18s ease; }
    .btn:hover { transform:translateY(-1px); filter:brightness(1.02); }
    .primary { color:#fff; background:var(--blue); }
    .secondary { color:var(--ink); background:#edf1f7; }
    .success { color:#fff; background:var(--green); }
    .danger { color:#fff; background:var(--red); }
    .side h2 { font-size:1rem; margin:0 0 12px; }
    .stat { display:flex; justify-content:space-between; gap:10px; padding:10px 0; border-bottom:1px solid var(--line); font-size:.91rem; }
    .stat:last-child { border-bottom:0; }
    .stat span:last-child { font-weight:850; }
    .side-actions { display:grid; gap:9px; margin-top:18px; }
    .side-actions .btn { width:100%; }
    .hint { color:var(--muted); font-size:.83rem; margin-top:18px; }
    .result { display:none; padding:28px; margin-bottom:22px; background:linear-gradient(135deg,#f0f7ff,#fff); border:1px solid #cfe0ff; border-radius:18px; }
    .result.show { display:block; }
    .result h2 { margin:0 0 8px; }
    .score { font-size:2.6rem; font-weight:900; color:var(--blue); letter-spacing:-.05em; }
    .review-grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(94px,1fr)); gap:8px; max-height:410px; overflow:auto; padding-right:3px; }
    .jump { border:1px solid var(--line); background:#fbfcfe; border-radius:10px; padding:8px 5px; cursor:pointer; font-weight:800; font-size:.78rem; }
    .jump.current { outline:3px solid var(--blue-soft); border-color:var(--blue); }
    .jump.right { background:var(--green-soft); border-color:#a6dfc6; color:#126c4c; }
    .jump.wrong { background:var(--red-soft); border-color:#f2b5b5; color:#9f3030; }
    .footer { text-align:center; color:var(--muted); font-size:.8rem; margin-top:30px; }
    @media (max-width:850px) { .layout { grid-template-columns:1fr; } .side { position:static; order:-1; } .hero { padding:28px 24px; } .quiz { padding:22px; } }
    @media (max-width:520px) { .shell { padding:14px 10px 40px; } .toolbar > * { width:100%; } .toolbar label { width:auto; } }
  </style>
</head>
<body>
  <main class="shell">
    <header class="hero">
      <div class="eyebrow">Prepared for __OWNER__</div>
      <h1>Series 65 Practice Bank</h1>
      <p>270 original English questions with answer choices, verified answers, explanations, progress tracking, scoring, and review tools.</p>
      <div class="hero-note">Standalone study companion - No internet connection required - Generated __GENERATED__</div>
    </header>

    <div class="toolbar">
      <label for="mode">Practice mode</label>
      <select id="mode" aria-label="Practice mode">
        <option value="all">All questions</option>
        <option value="unanswered">Unanswered only</option>
        <option value="incorrect">Incorrect answers</option>
      </select>
      <label for="section">Section</label>
      <select id="section" aria-label="Filter by section">
        <option value="all">All sections</option>
        <option value="economic">Economic Factors</option>
        <option value="vehicles">Investment Vehicles</option>
        <option value="recommendations">Recommendations & Strategies</option>
        <option value="law">Laws, Regulations & Ethics</option>
        <option value="highyield">High-Yield Expansion</option>
      </select>
      <button class="btn secondary" id="shuffleBtn" type="button">Shuffle questions</button>
    </div>

    <section class="result" id="result" aria-live="polite">
      <h2>Practice summary</h2>
      <div class="score" id="score">0%</div>
      <p id="scoreText">Answer questions to see your result.</p>
      <button class="btn primary" id="restartBtn" type="button">Restart current set</button>
    </section>

    <div class="layout">
      <section class="card quiz" aria-label="Question card">
        <div class="meta"><span id="questionLabel">Question 1 of 270</span><span id="sectionLabel">Section</span></div>
        <div class="progress" aria-label="Progress"><div id="progressBar"></div></div>
        <h2 class="question" id="prompt"></h2>
        <div class="options" id="options"></div>
        <div class="feedback" id="feedback" aria-live="polite"></div>
        <div class="actions">
          <button class="btn secondary" id="prevBtn" type="button">Previous</button>
          <button class="btn primary" id="checkBtn" type="button">Check answer</button>
          <button class="btn primary" id="nextBtn" type="button">Next question</button>
        </div>
      </section>

      <aside class="card side">
        <h2>Session overview</h2>
        <div class="stat"><span>Answered</span><span id="answeredStat">0 / 270</span></div>
        <div class="stat"><span>Correct</span><span id="correctStat">0</span></div>
        <div class="stat"><span>Accuracy</span><span id="accuracyStat">--</span></div>
        <div class="side-actions">
          <button class="btn success" id="finishBtn" type="button">Finish & score</button>
          <button class="btn secondary" id="resetBtn" type="button">Reset all progress</button>
        </div>
        <p class="hint">Select an answer, check it, and use the question map to revisit any item. Your progress is stored only in this browser.</p>
        <h2 style="margin-top:24px">Question map</h2>
        <div class="review-grid" id="questionMap"></div>
      </aside>
    </div>
    <div class="footer">Original study material based on public NASAA, SEC, DOL, and IRS concepts. Not an official NASAA or ExamFX product.</div>
  </main>

  <script>
    const QUESTIONS = __QUESTIONS__;
    const state = { answers:{}, checked:{}, current:0, order:QUESTIONS.map((_,i)=>i), filtered:QUESTIONS.map((_,i)=>i) };
    const $ = (id) => document.getElementById(id);
    const sectionFor = (id) => {
      const n = Number(id.slice(1));
      if (n <= 20) return ['economic','Economic Factors'];
      if (n <= 55) return ['vehicles','Investment Vehicle Characteristics'];
      if (n <= 90) return ['recommendations','Client Investment Recommendations and Strategies'];
      if (n <= 150) return ['law','Laws, Regulations and Ethical Practices'];
      return ['highyield','High-Yield Expansion'];
    };
    const currentQuestion = () => QUESTIONS[state.order[state.filtered[state.current]]];
    const visibleIndex = () => state.filtered[state.current];

    function refreshFilter() {
      const mode = $('mode').value;
      const section = $('section').value;
      state.filtered = state.order.map((qIndex, position) => ({ qIndex, position })).filter(item => {
        const q = QUESTIONS[item.qIndex];
        const sectionMatch = section === 'all' || sectionFor(q.id)[0] === section;
        const modeMatch = mode === 'all' || (mode === 'unanswered' && state.answers[q.id] === undefined) || (mode === 'incorrect' && state.checked[q.id] && state.answers[q.id] !== q.answer);
        return sectionMatch && modeMatch;
      }).map(item => item.position);
      if (!state.filtered.length) state.current = 0; else state.current = Math.min(state.current, state.filtered.length - 1);
      render();
    }

    function render() {
      const q = currentQuestion();
      if (!q) return;
      const section = sectionFor(q.id);
      $('questionLabel').textContent = `Question ${q.id.slice(1)} of 270`;
      $('sectionLabel').textContent = section[1];
      $('prompt').textContent = q.prompt;
      $('progressBar').style.width = `${((state.current + 1) / Math.max(1,state.filtered.length)) * 100}%`;
      $('options').innerHTML = Object.entries(q.options).map(([letter,text]) => {
        const selected = state.answers[q.id] === letter;
        const checked = state.checked[q.id];
        const cls = checked && letter === q.answer ? 'correct' : (checked && selected && letter !== q.answer ? 'incorrect' : (selected ? 'selected' : ''));
        return `<button class="option ${cls}" data-letter="${letter}" type="button"><span class="letter">${letter}</span>${text}</button>`;
      }).join('');
      document.querySelectorAll('.option').forEach(btn => btn.addEventListener('click', () => { state.answers[q.id] = btn.dataset.letter; state.checked[q.id] = false; render(); }));
      const feedback = $('feedback');
      feedback.className = 'feedback';
      if (state.checked[q.id]) {
        const correct = state.answers[q.id] === q.answer;
        feedback.classList.add('show', correct ? 'correct' : 'incorrect');
        feedback.innerHTML = `<strong>${correct ? 'Correct' : `Incorrect - the correct answer is ${q.answer}`}</strong>${q.explanation}`;
      } else if (state.answers[q.id]) {
        feedback.classList.add('show');
        feedback.innerHTML = '<strong>Answer selected</strong>Click Check answer to reveal the explanation.';
      } else {
        feedback.innerHTML = '';
      }
      $('prevBtn').disabled = state.current === 0;
      $('nextBtn').disabled = state.current >= state.filtered.length - 1;
      updateStats();
      renderMap();
    }

    function check() {
      const q = currentQuestion();
      if (!state.answers[q.id]) { $('feedback').className = 'feedback show incorrect'; $('feedback').innerHTML = '<strong>Select an answer first</strong>Choose one option before checking.'; return; }
      state.checked[q.id] = true; render();
    }

    function updateStats() {
      const answered = Object.keys(state.answers).length;
      const correct = Object.keys(state.checked).filter(id => state.checked[id] && state.answers[id] === QUESTIONS.find(q => q.id === id).answer).length;
      const checked = Object.keys(state.checked).filter(id => state.checked[id]).length;
      $('answeredStat').textContent = `${answered} / 270`;
      $('correctStat').textContent = correct;
      $('accuracyStat').textContent = checked ? `${Math.round((correct / checked) * 100)}%` : '--';
    }

    function renderMap() {
      $('questionMap').innerHTML = state.order.map((qIndex, position) => {
        const q = QUESTIONS[qIndex];
        const classes = [position === visibleIndex() ? 'current' : ''];
        if (state.checked[q.id]) classes.push(state.answers[q.id] === q.answer ? 'right' : 'wrong');
        return `<button class="jump ${classes.join(' ')}" data-position="${position}" type="button">${q.id}</button>`;
      }).join('');
      document.querySelectorAll('.jump').forEach(btn => btn.addEventListener('click', () => {
        const position = Number(btn.dataset.position); const index = state.filtered.indexOf(position);
        if (index >= 0) { state.current = index; render(); }
      }));
    }

    function score() {
      const checked = Object.keys(state.checked).filter(id => state.checked[id]);
      const correct = checked.filter(id => state.answers[id] === QUESTIONS.find(q => q.id === id).answer).length;
      const percent = checked.length ? Math.round((correct / checked.length) * 100) : 0;
      $('score').textContent = `${percent}%`;
      $('scoreText').textContent = checked.length ? `${correct} correct out of ${checked.length} checked questions. Review incorrect answers before your next attempt.` : 'No answers have been checked yet.';
      $('result').classList.add('show');
      $('result').scrollIntoView({behavior:'smooth',block:'start'});
    }

    function resetAll() {
      if (!confirm('Reset all answers and progress?')) return;
      state.answers = {}; state.checked = {}; state.current = 0; $('result').classList.remove('show'); refreshFilter();
    }

    $('checkBtn').addEventListener('click', check);
    $('prevBtn').addEventListener('click', () => { if (state.current > 0) { state.current--; render(); } });
    $('nextBtn').addEventListener('click', () => { if (state.current < state.filtered.length - 1) { state.current++; render(); } });
    $('finishBtn').addEventListener('click', score);
    $('resetBtn').addEventListener('click', resetAll);
    $('restartBtn').addEventListener('click', () => { state.answers = {}; state.checked = {}; state.current = 0; $('result').classList.remove('show'); refreshFilter(); });
    $('mode').addEventListener('change', refreshFilter);
    $('section').addEventListener('change', refreshFilter);
    $('shuffleBtn').addEventListener('click', () => { state.order = [...state.order].sort(() => Math.random() - .5); state.current = 0; refreshFilter(); });
    render();
  </script>
</body>
</html>
'@

$html = $html.Replace('__TITLE__', $title).Replace('__GENERATED__', $generated).Replace('__OWNER__', $ownerName).Replace('__QUESTIONS__', $json)
[System.IO.File]::WriteAllText($htmlPath, $html, $utf8)
Write-Output "Generated $htmlPath with $($questions.Count) questions."
