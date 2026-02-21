<script>
  import { docs } from './lib/docs';
  import { onMount } from 'svelte';

  let currentCategory = docs[0];
  let currentSection = docs[0].sections[0];
  let isNavOpen = false;
  let scrolled = false;
  let view = 'home'; // 'home' | 'docs' | 'benchmarks' | 'community'

  onMount(() => {
    window.addEventListener('scroll', () => {
      scrolled = window.scrollY > 20;
    });
    
    // Simple Router
    const handleHash = () => {
      const hash = window.location.hash;
      if (hash.startsWith('#/docs')) {
          view = 'docs';
      } else if (hash === '#/benchmarks') {
          view = 'benchmarks';
      } else if (hash === '#/community') {
          view = 'community';
      } else {
          view = 'home';
      }
    };
    
    window.addEventListener('hashchange', handleHash);
    handleHash();
  });

  function selectSection(cat, sec) {
    currentCategory = cat;
    currentSection = sec;
    view = 'docs';
    isNavOpen = false;
    window.scrollTo({ top: 0, behavior: 'smooth' });
    window.location.hash = `#/docs/${cat.id}/${sec.id}`;
  }

  $: allSections = docs.flatMap(c => c.sections.map(s => ({ ...s, cat: c })));
  $: currentIndex = allSections.findIndex(s => s.id === currentSection.id);
  $: prevSection = currentIndex > 0 ? allSections[currentIndex - 1] : null;
  $: nextSection = currentIndex < allSections.length - 1 ? allSections[currentIndex + 1] : null;

  function goHome() {
    view = 'home';
    window.location.hash = '';
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  const features = [
    { title: 'Trie-based Routing', desc: 'Lightning fast routing with support for dynamic parameters and middleware groups.', icon: '🚀' },
    { title: 'Fluent ORM', desc: 'Secure, parameterized query builder for PostgreSQL with atomic migrations.', icon: '🗄️' },
    { title: 'Scoped DI', desc: 'Request-scoped dependency injection ensures no state leaks between concurrent users.', icon: '🧪' },
    { title: 'Declarative Validation', desc: 'Validate input using simple string rules like "required|email|min:8".', icon: '✅' },
    { title: 'Hot Reload', desc: 'Built-in file watcher for a seamless development experience.', icon: '🔥' },
    { title: 'Typed Middlewares', desc: 'Robust pipeline for handling auth, logging, and CORS with ease.', icon: '🛡️' }
  ];

  let searchQuery = '';
  
  $: filteredDocs = docs.map(cat => ({
    ...cat,
    sections: cat.sections.filter(sec => 
      sec.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      cat.title.toLowerCase().includes(searchQuery.toLowerCase())
    )
  })).filter(cat => cat.sections.length > 0);

  function copyToClipboard(text) {
    navigator.clipboard.writeText(text);
    // Add a toast or small notification here if needed
  }

  function formatContent(text) {
    if (!text) return '';
    
    let html = text
      // 1. Multiline Code Blocks
      .replace(/```(?:dart|bash|javascript|json)?\s*\n([\s\S]*?)\n```/g, (match, code) => {
          const cleanCode = code.trim().replace(/'/g, "\\'");
          return `<div class="code-block-wrapper">
                    <div class="code-block-header">
                        <div class="window-controls">
                            <span class="control red"></span>
                            <span class="control yellow"></span>
                            <span class="control green"></span>
                        </div>
                        <span class="lang-label">${match.includes('bash') ? 'Terminal' : 'Source'}</span>
                        <button class="copy-btn" onclick="this.innerText='Copied!'; setTimeout(()=>this.innerText='Copy', 2000); navigator.clipboard.writeText('${cleanCode}')">Copy</button>
                    </div>
                    <div class="code-block"><pre><code>${code.trim()}</code></pre></div>
                  </div>`;
      })
      // 2. Headers
      .replace(/^### (.*$)/gm, (m, p1) => `<h3 class="doc-h3" id="${p1.toLowerCase().replace(/\s+/g, '-')}">${p1}</h3>`)
      .replace(/^## (.*$)/gm, (m, p1) => `<h2 class="doc-h2" id="${p1.toLowerCase().replace(/\s+/g, '-')}">${p1}</h2>`)
      // 3. Bold
      .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
      // 4. Inline Code
      .replace(/`([^`\n]+)`/g, '<code class="inline-code">$1</code>')
      // 5. Lists
      .replace(/^\s*- (.*)$/gm, '<li>$1</li>');

    const lines = html.split('\n');
    const processedLines = lines.map(line => {
        const trimmed = line.trim();
        if (!trimmed) return '';
        if (trimmed.startsWith('<h') || trimmed.startsWith('<div') || trimmed.startsWith('<li') || trimmed.startsWith('</')) {
            return line;
        }
        return `<p>${line}</p>`;
    });

    return processedLines.join('\n');
  }
</script>

<div class="grid-background"></div>
<div class="bg-blobs">
    <div class="blob blob-1"></div>
    <div class="blob blob-2"></div>
    <div class="blob blob-3"></div>
</div>

<!-- Header -->
<nav class="navbar" class:scrolled>
  <div class="container nav-content">
    <div 
      class="logo" 
      on:click={goHome} 
      on:keydown={(e) => e.key === 'Enter' && goHome()}
      role="button"
      tabindex="0"
      style="cursor: pointer"
    >
      <span class="gradient-text">DartX</span>
    </div>
    <div class="nav-links">
      <a href="#features" class:active={view === 'home'} on:click|preventDefault={goHome}>Features</a>
      <a href="#/docs" class:active={view === 'docs'} on:click|preventDefault={() => window.location.hash = '#/docs'}>Docs</a>
      <a href="#/benchmarks" class:active={view === 'benchmarks'} on:click|preventDefault={() => window.location.hash = '#/benchmarks'}>Benchmarks</a>
      <a href="#/community" class:active={view === 'community'} on:click|preventDefault={() => window.location.hash = '#/community'}>Community</a>
      <a href="https://github.com/garv/dartx" target="_blank" class="github-link">
          <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/></svg>
      </a>
      <button class="btn-primary" on:click={() => (window.location.hash = '#/docs')}>Get Started</button>
    </div>
    <button 
      class="mobile-toggle" 
      on:click={() => isNavOpen = !isNavOpen}
      aria-label="Toggle Menu"
    >
      {isNavOpen ? '✕' : '☰'}
    </button>
  </div>
</nav>

{#if view === 'home'}
  <!-- HERO -->
  <main class="animate-fade-in">
    <section class="hero container">
      <div class="hero-content">
        <div class="badge">v1.2.4 Stabilized</div>
        <h1 class="hero-title">Architect <br/><span class="gradient-text">Hardened</span> APIs</h1>
        <p class="hero-subtitle">The enterprise-grade backend framework for Dart. Built-in DI, ORM, and Validation for developers who don't compromise on architecture.</p>
        <div class="scroll-indicator">
            <div class="mouse"></div>
            <span>Scroll to explore</span>
        </div>
        <div class="hero-actions">
          <button class="btn-primary" on:click={() => (view = 'docs')}>Read the Docs</button>
          <button class="btn-secondary">View Benchmarks</button>
        </div>
      </div>
      
      <div class="hero-image glass">
        <div class="window-header">
            <div class="dot red"></div><div class="dot yellow"></div><div class="dot green"></div>
            <span class="file-name">main.dart</span>
        </div>
        <pre><code><span class="keyword">import</span> <span class="string">'package:dartx/dartx.dart'</span>;

<span class="keyword">void</span> <span class="function">main</span>() <span class="keyword">async</span> {'{'}
  <span class="keyword">final</span> app = <span class="class">App</span>();

  app.<span class="function">get</span>(<span class="string">'/orders/:id'</span>, (ctx) <span class="keyword">async</span> {'{'}
    <span class="keyword">final</span> db = ctx.<span class="function">resolve</span>&lt;<span class="class">Database</span>&gt;();
    <span class="keyword">return</span> ctx.<span class="function">json</span>(
      <span class="keyword">await</span> db.<span class="function">table</span>(<span class="string">'orders'</span>).<span class="function">find</span>(ctx.params[<span class="string">'id'</span>])
    );
  {'}'});

  <span class="keyword">await</span> app.<span class="function">listen</span>(port: <span class="number">8080</span>);
{'}'}</code></pre>
      </div>
    </section>

    <!-- FEATURES -->
    <section id="features" class="container" style="padding: 100px 0;">
      <h2 class="section-title">Built for <span class="gradient-text">Performance</span></h2>
      <div class="features-grid">
        {#each features as feature}
          <div class="feature-card glass">
            <div class="feature-icon">{feature.icon}</div>
            <h3>{feature.title}</h3>
            <p>{feature.desc}</p>
          </div>
        {/each}
      </div>
    </section>

    <!-- QUICK START -->
    <section class="container" style="padding: 100px 0;">
        <div class="glass quick-start">
            <div class="quick-start-info">
                <h2 style="font-size: 36px; margin-bottom: 20px;">Quick <span class="gradient-text">Start</span></h2>
                <p style="color: var(--text-muted); margin-bottom: 30px;">Get your API up and running in less than 60 seconds.</p>
                <ul class="step-list">
                    <li><span class="step-num">1</span> Global Install</li>
                    <li><span class="step-num">2</span> Project Scaffold</li>
                    <li><span class="step-num">3</span> Live Development</li>
                </ul>
            </div>
            <div class="quick-start-terminal">
                <div class="terminal-header">
                    <span>bash</span>
                </div>
                <div class="terminal-body">
                    <p><span class="prompt">$</span> dart pub global activate dartx</p>
                    <p><span class="prompt">$</span> dartx create my_api</p>
                    <p><span class="prompt">$</span> cd my_api && dartx watch</p>
                    <p class="success">🚀 Server started on http://0.0.0.0:3000</p>
                </div>
            </div>
        </div>
    </section>

    <!-- CTAs -->
    <section class="container" style="text-align: center; padding-bottom: 150px;">
        <div class="glass" style="padding: 80px; border-radius: 32px;">
            <h2 style="font-size: 42px; margin-bottom: 20px;">Ready to build?</h2>
            <p style="color: var(--text-muted); margin-bottom: 40px; font-size: 18px;">Join thousands of developers building the next generation of APIs.</p>
            <button class="btn-primary glow" style="padding: 16px 48px; font-size: 18px;" on:click={() => (view = 'docs')}>Start Free Today</button>
        </div>
    </section>
  </main>
{:else}
  <!-- DOCUMENTATION VIEW -->
  <div class="docs-page container animate-fade-in">
    <aside class="docs-sidebar" class:open={isNavOpen}>
      <div class="sidebar-search">
        <input 
          type="text" 
          placeholder="Search docs..." 
          bind:value={searchQuery}
        />
      </div>
      <div class="sidebar-content">
        {#each filteredDocs as category}
          <div class="sidebar-category">
            <h4>{category.title}</h4>
            <ul>
              {#each category.sections as section}
                <li>
                  <button 
                    class:active={currentSection.id === section.id}
                    on:click={() => selectSection(category, section)}
                  >
                    {section.title}
                  </button>
                </li>
              {/each}
            </ul>
          </div>
        {:else}
          <p style="padding: 20px; color: var(--text-muted); font-size: 14px;">No results found.</p>
        {/each}
      </div>
    </aside>
    
    <main class="docs-main-content">
      <div class="docs-inner">
        <div class="breadcrumb">
          Documentation / {currentCategory.title} / {currentSection.title}
        </div>
        
        <h1 class="docs-title">{currentSection.title}</h1>
        <div class="rendered-content">
          {@html formatContent(currentSection.content)}
        </div>

        <div class="pagination">
          <div class="nav-btns">
            {#if prevSection}
                <button class="nav-btn prev" on:click={() => selectSection(prevSection.cat, prevSection)}>
                    <span class="label">Previous</span>
                    <span class="title">{prevSection.title}</span>
                </button>
            {:else}
                <div></div>
            {/if}
            
            {#if nextSection}
                <button class="nav-btn next" on:click={() => selectSection(nextSection.cat, nextSection)}>
                    <span class="label">Next</span>
                    <span class="title">{nextSection.title}</span>
                </button>
            {/if}
          </div>
          <button class="btn-secondary" style="margin-top: 40px; width: 100%;" on:click={goHome}>← Back Home</button>
        </div>
      </div>
    </main>

    <aside class="docs-right-sidebar desktop-only">
      <div class="right-sidebar-content">
        <h5>On this page</h5>
        <nav>
          <ul>
            {#each currentSection.content.matchAll(/^#+ (.*)/gm) as match}
                <li><a href="#{match[1].toLowerCase().replace(/\s+/g, '-')}" on:click|preventDefault={() => {
                    const el = document.getElementById(match[1].toLowerCase().replace(/\s+/g, '-'));
                    if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }}>{match[1]}</a></li>
            {/each}
          </ul>
        </nav>
      </div>
    </aside>
  </div>
{/if}

{#if view === 'benchmarks'}
  <div class="container animate-fade-in" style="padding: 160px 0;">
    <h1 class="section-title">Performance <span class="gradient-text">Analysis</span></h1>
    <p style="text-align: center; color: var(--text-muted); margin-bottom: 60px; font-size: 18px;">Real-world micro-benchmarks conducted on the DartX core engine.</p>
    
    <div class="bench-grid">
        <div class="glass bench-card">
            <h3>Internal Latency (µs)</h3>
            <p style="color: var(--text-muted); font-size: 14px; margin-bottom: 32px;">Lower is better. Measured per single operation overhead.</p>
            <div class="chart">
                <div class="bar-group">
                    <div class="bar-label">Routing</div>
                    <div class="bar-wrapper"><div class="bar primary" style="width: 26%"></div></div>
                    <div class="bar-value">1.3 µs</div>
                </div>
                <div class="bar-group">
                    <div class="bar-label">Validation</div>
                    <div class="bar-wrapper"><div class="bar primary" style="width: 54%"></div></div>
                    <div class="bar-value">2.7 µs</div>
                </div>
                <div class="bar-group">
                    <div class="bar-label">DI Resolve</div>
                    <div class="bar-wrapper"><div class="bar primary" style="width: 18%"></div></div>
                    <div class="bar-value">0.9 µs</div>
                </div>
            </div>
        </div>

        <div class="glass bench-card">
            <h3>Requests / Sec</h3>
            <div class="stat-large">84.2<span class="unit">k</span></div>
            <p style="color: var(--text-muted); font-size: 14px; margin-top: 10px;">Throughput on M1 Max (Raw JSON)</p>
        </div>
    </div>

    <!-- Framework Deep Dive -->
    <div class="tech-deep-dive" style="margin-top: 120px;">
        <h2 class="section-title">Framework <span class="gradient-text">DNA</span></h2>
        <div class="features-grid">
            <div class="glass feature-card">
                <span class="feature-icon">🌿</span>
                <h3>Radix-Trie Router</h3>
                <p>O(n) matching complexity where 'n' is path segments. Routing speed remains constant regardless of the number of registered routes (tested up to 10k routes).</p>
            </div>
            <div class="glass feature-card">
                <span class="feature-icon">📦</span>
                <h3>Scoped Container</h3>
                <p>Every request gets a dedicated child container. This ensures 100% isolation of stateful services like DB sessions and Auth contexts.</p>
            </div>
            <div class="glass feature-card">
                <span class="feature-icon">♻️</span>
                <h3>Disposable Pattern</h3>
                <p>Automatic resource cleanup. Services implementing 'Disposable' are awaited and cleared before the response socket is released.</p>
            </div>
        </div>
    </div>
  </div>
{/if}

{#if view === 'community'}
  <div class="container animate-fade-in" style="padding: 160px 0; text-align: center;">
    <h1 class="section-title">Join the <span class="gradient-text">Ecosystem</span></h1>
    <div class="community-grid">
        <a href="#" class="glass comm-card">
            <div class="icon">💬</div>
            <h3>Discord</h3>
            <p>Chat with the core team and fellow developers.</p>
        </a>
        <a href="#" class="glass comm-card">
            <div class="icon">🐦</div>
            <h3>Twitter</h3>
            <p>Get the latest news and ecosystem updates.</p>
        </a>
        <a href="#" class="glass comm-card">
            <div class="icon">📖</div>
            <h3>GitHub</h3>
            <p>Contribute to the core framework and plugins.</p>
        </a>
    </div>
  </div>
{/if}

<footer class="site-footer">
    <div class="container footer-content">
        <div class="footer-brand">
            <div class="logo"><span class="gradient-text">DartX</span></div>
            <p>Architect hardened APIs with ease.</p>
        </div>
        <div class="footer-links">
            <div>
                <h4>Resources</h4>
                <ul>
                    <li><a href="#/docs">Documentation</a></li>
                    <li><a href="#/benchmarks">Benchmarks</a></li>
                    <li><a href="#">Showcase</a></li>
                </ul>
            </div>
            <div>
                <h4>Ecosystem</h4>
                <ul>
                    <li><a href="https://github.com">GitHub</a></li>
                    <li><a href="#">Plugins</a></li>
                    <li><a href="#">CLI Tool</a></li>
                </ul>
            </div>
            <div>
                <h4>Legal</h4>
                <ul>
                    <li><a href="#">Privacy</a></li>
                    <li><a href="#">Terms</a></li>
                    <li><a href="#">License</a></li>
                </ul>
            </div>
        </div>
    </div>
    <div class="container footer-bottom">
        <p>&copy; 2026 DartX Framework. Built with ❤️ for the Dart community.</p>
    </div>
</footer>

<style>
  /* Base Layout */
  .container {
    max-width: 1240px;
    margin: 0 auto;
    padding: 0 24px;
  }

  /* Global Button Reset */
  button {
    font-family: inherit;
    border: none;
    background: none;
    cursor: pointer;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  }

  .btn-primary {
    background: var(--primary);
    color: white;
    padding: 12px 28px;
    border-radius: 12px;
    font-weight: 700;
    font-size: 15px;
    box-shadow: 0 10px 20px -10px rgba(99, 102, 241, 0.5);
  }

  .btn-primary:hover {
    transform: translateY(-2px);
    box-shadow: 0 15px 30px -10px rgba(99, 102, 241, 0.6);
    filter: brightness(1.1);
  }

  .btn-secondary {
    background: rgba(255, 255, 255, 0.05);
    color: white;
    padding: 12px 28px;
    border-radius: 12px;
    font-weight: 600;
    font-size: 15px;
    border: 1px solid var(--glass-border);
    backdrop-filter: blur(4px);
  }

  .btn-secondary:hover {
    background: rgba(255, 255, 255, 0.1);
    border-color: rgba(255, 255, 255, 0.2);
    transform: translateY(-2px);
  }

  /* Navbar */
  .navbar {
    position: fixed;
    top: 20px;
    left: 0;
    right: 0;
    height: 70px;
    z-index: 1000;
    transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
  }

  .navbar.scrolled {
    top: 0;
    background: rgba(15, 23, 42, 0.8);
    backdrop-filter: blur(12px);
    border-bottom: 1px solid var(--glass-border);
  }

  .nav-content {
    display: flex;
    justify-content: space-between;
    align-items: center;
    height: 100%;
    background: rgba(30, 41, 59, 0.4);
    backdrop-filter: blur(10px);
    border: 1px solid var(--glass-border);
    border-radius: 20px;
    padding: 0 24px;
    transition: all 0.4s;
  }

  .navbar.scrolled .nav-content {
      border-radius: 0;
      border: none;
      background: transparent;
      width: 100%;
      max-width: 100%;
  }

  .logo { font-size: 26px; font-weight: 800; }
  .nav-links { display: flex; gap: 32px; align-items: center; }
  .nav-links a { color: var(--text-muted); text-decoration: none; font-size: 14px; font-weight: 500; transition: 0.2s; position: relative; }
  .nav-links a:hover, .nav-links a.active { color: white; }
  .nav-links a.active::after {
      content: '';
      position: absolute;
      bottom: -4px; left: 0; width: 100%; height: 2px;
      background: var(--primary);
      border-radius: 2px;
  }

  /* Hero */
  .hero {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 60px;
    align-items: center;
    padding: 180px 0 100px;
  }

  .hero-title { 
    font-size: clamp(56px, 10vw, 88px); 
    line-height: 0.95; 
    margin-bottom: 24px; 
    font-weight: 900;
  }
  .hero-subtitle { 
    font-size: 20px; 
    color: var(--text-muted); 
    margin-bottom: 48px; 
    max-width: 540px; 
    line-height: 1.6;
  }
  .hero-actions { display: flex; gap: 16px; flex-wrap: wrap; margin-top: 20px; }

  .hero-image {
    padding: 30px;
    font-family: 'Fira Code', monospace;
    font-size: 13px;
    line-height: 1.5;
    box-shadow: 0 50px 100px -20px rgba(0,0,0,0.5);
    border-radius: 20px;
    max-width: 100%;
    overflow: hidden;
    animation: hero-float 6s ease-in-out infinite;
  }

  @keyframes hero-float {
      0%, 100% { transform: translateY(0); }
      50% { transform: translateY(-20px); }
  }

  .scroll-indicator {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-top: 60px;
      color: var(--text-muted);
      font-size: 12px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 1px;
      opacity: 0.5;
  }

  .mouse {
      width: 20px;
      height: 32px;
      border: 2px solid var(--text-muted);
      border-radius: 10px;
      position: relative;
  }
  .mouse::after {
      content: '';
      position: absolute;
      top: 6px; left: 50%;
      transform: translateX(-50%);
      width: 4px; height: 8px;
      background: var(--primary);
      border-radius: 2px;
      animation: mouse-scroll 1.5s infinite;
  }

  @keyframes mouse-scroll {
      0% { transform: translateX(-50%) translateY(0); opacity: 1; }
      100% { transform: translateX(-50%) translateY(10px); opacity: 0; }
  }

  /* Docs Layout */
  .docs-page {
    display: grid;
    grid-template-columns: 280px 1fr 240px;
    gap: 40px;
    padding-top: 120px;
    min-height: 100vh;
  }
  
  @media (max-width: 1280px) {
      .docs-page { grid-template-columns: 260px 1fr; }
      .desktop-only { display: none; }
  }

  /* Right Sidebar */
  .docs-right-sidebar {
      position: sticky;
      top: 120px;
      height: calc(100vh - 120px);
      padding-left: 20px;
      border-left: 1px solid var(--glass-border);
  }

  .right-sidebar-content h5 {
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: white;
      margin-bottom: 16px;
      opacity: 0.5;
  }

  .right-sidebar-content ul { list-style: none; }
  .right-sidebar-content li { margin-bottom: 10px; }
  .right-sidebar-content a {
      font-size: 13px;
      color: var(--text-muted);
      text-decoration: none;
      transition: all 0.2s;
  }
  .right-sidebar-content a:hover { color: var(--primary); }

  .docs-sidebar {
    position: sticky;
    top: 120px;
    height: calc(100vh - 120px);
    overflow-y: auto;
    padding-bottom: 40px;
    display: flex;
    flex-direction: column;
  }

  .sidebar-search {
    padding: 0 0 24px;
    margin-bottom: 24px;
    border-bottom: 1px solid var(--glass-border);
  }

  .sidebar-search input {
    width: 100%;
    background: rgba(15, 23, 42, 0.5);
    border: 1px solid var(--glass-border);
    border-radius: 12px;
    padding: 10px 16px;
    color: white;
    font-size: 14px;
    transition: all 0.2s;
  }

  .sidebar-search input:focus {
    outline: none;
    border-color: var(--primary);
    box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.1);
  }

  .sidebar-content {
      padding-right: 15px;
      flex: 1;
      overflow-y: auto;
  }

  .sidebar-content::-webkit-scrollbar {
    width: 4px;
  }
  .sidebar-content::-webkit-scrollbar-thumb {
    background: var(--glass-border);
    border-radius: 10px;
  }

  .sidebar-category { margin-bottom: 32px; }
  .sidebar-category h4 { 
    color: white; 
    font-size: 11px; 
    text-transform: uppercase; 
    letter-spacing: 2px; 
    margin-bottom: 12px; 
    opacity: 0.3;
    font-weight: 800;
    padding-left: 12px;
  }
  .sidebar-category ul { list-style: none; }
  .sidebar-category button {
    background: none;
    border: none;
    color: var(--text-muted);
    padding: 10px 14px;
    font-size: 14px;
    cursor: pointer;
    transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    width: 100%;
    text-align: left;
    border-radius: 10px;
    border-left: 2px solid transparent;
    display: block;
    margin-bottom: 2px;
  }
  .sidebar-category button:hover {
    color: white;
    background: rgba(255, 255, 255, 0.04);
    transform: translateX(4px);
  }
  .sidebar-category button.active {
    color: var(--primary);
    background: rgba(99, 102, 241, 0.1);
    border-left: 2px solid var(--primary);
    font-weight: 600;
  }

  .docs-main-content {
      padding-bottom: 100px;
  }
  
  .docs-inner {
      max-width: 860px;
  }

  .docs-title { 
    font-size: clamp(34px, 6vw, 52px); 
    margin-bottom: 24px; 
    font-weight: 800; 
    letter-spacing: -0.03em;
    line-height: 1.1;
  }
  .breadcrumb { 
    color: var(--primary); 
    font-size: 11px; 
    font-weight: 700; 
    text-transform: uppercase; 
    letter-spacing: 1.5px; 
    margin-bottom: 16px; 
    opacity: 0.7; 
  }

  .pagination {
      margin-top: 100px;
      padding-top: 60px;
      border-top: 1px solid var(--glass-border);
  }

  .nav-btns {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 20px;
  }

  .nav-btn {
      padding: 24px;
      background: var(--card-bg);
      border: 1px solid var(--glass-border);
      border-radius: 16px;
      text-align: left;
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      display: flex;
      flex-direction: column;
      gap: 4px;
  }

  .nav-btn.next { text-align: right; }
  .nav-btn:hover {
      border-color: var(--primary);
      background: rgba(99, 102, 241, 0.05);
      transform: translateY(-4px);
  }

  .nav-btn .label {
      font-size: 11px;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: var(--text-muted);
      font-weight: 700;
  }

  .nav-btn .title {
      font-size: 18px;
      font-weight: 700;
      color: white;
  }

  /* Custom Content Rendering */
  :global(.doc-h2) { font-size: 32px; margin: 56px 0 24px; border-bottom: 1px solid var(--glass-border); padding-bottom: 16px; font-weight: 700; }
  :global(.doc-h3) { font-size: 24px; margin: 40px 0 16px; color: var(--secondary); font-weight: 600; }
  :global(.inline-code) { background: rgba(99, 102, 241, 0.15); color: #a5b4fc; padding: 3px 7px; border-radius: 6px; font-family: 'Fira Code', monospace; font-size: 0.9em; }
  
  :global(.code-block-wrapper) {
      margin: 32px 0;
      background: #0b1120;
      border: 1px solid var(--glass-border);
      border-radius: 16px;
      overflow: hidden;
      box-shadow: 0 10px 30px -10px rgba(0,0,0,0.5);
  }

  :global(.code-block-header) {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px 20px;
      background: rgba(255, 255, 255, 0.05);
      border-bottom: 1px solid var(--glass-border);
  }

  :global(.window-controls) {
      display: flex;
      gap: 8px;
  }

  :global(.window-controls .control) {
      width: 10px;
      height: 10px;
      border-radius: 50%;
  }

  :global(.control.red) { background: #ff5f56; }
  :global(.control.yellow) { background: #ffbd2e; }
  :global(.control.green) { background: #27c93f; }

  :global(.lang-label) {
      position: absolute;
      left: 50%;
      transform: translateX(-50%);
      font-size: 11px;
      color: var(--text-muted);
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 1px;
  }

  :global(.copy-btn) {
      background: rgba(255, 255, 255, 0.03);
      border: 1px solid var(--glass-border);
      color: var(--text-muted);
      padding: 6px 12px;
      border-radius: 8px;
      cursor: pointer;
      font-size: 11px;
      font-weight: 600;
      transition: all 0.2s;
  }

  :global(.copy-btn:hover) {
      color: white;
      border-color: var(--primary);
      background: rgba(99, 102, 241, 0.15);
      transform: translateY(-1px);
  }

  :global(.code-block) { padding: 24px; overflow-x: auto; }
  :global(.code-block pre) { margin: 0; font-family: 'Fira Code', monospace; font-size: 14px; line-height: 1.6; }
  
  :global(.rendered-content p) { font-size: 18px; color: #cbd5e1; margin-bottom: 24px; line-height: 1.8; }
  :global(.rendered-content li) { color: #cbd5e1; margin: 12px 0 12px 24px; font-size: 17px; line-height: 1.6; }
  :global(.rendered-content li::marker) { color: var(--primary); }

  /* Code Syntax (Manual highlighting in template) */
  .keyword { color: #c084fc; font-weight: 600; }
  .string { color: #34d399; }
  .function { color: #818cf8; }
  .class { color: #fbbf24; }
  .number { color: #f472b6; }

  /* Feature Grid (Home) */
  .section-title {
    text-align: center;
    font-size: clamp(32px, 5vw, 48px);
    margin-bottom: 60px;
  }

  .features-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
    gap: 32px;
    margin-bottom: 100px;
  }

  .feature-card {
    padding: 40px;
    transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
    position: relative;
    overflow: hidden;
  }

  .feature-card:hover {
    transform: translateY(-8px);
    border-color: var(--primary);
    box-shadow: 0 20px 40px -10px rgba(0,0,0,0.3);
  }

  .feature-icon {
    font-size: 36px;
    margin-bottom: 20px;
    display: block;
  }

  .feature-card h3 {
    margin-bottom: 16px;
    font-size: 20px;
  }

  .feature-card p {
    color: var(--text-muted);
    font-size: 16px;
    line-height: 1.6;
  }

  .btn-primary.glow {
    position: relative;
    z-index: 1;
    overflow: visible;
  }

  .btn-primary.glow::after {
    content: '';
    position: absolute;
    top: 50%; left: 50%;
    transform: translate(-50%, -50%);
    width: 100%; height: 100%;
    background: var(--primary);
    border-radius: inherit;
    z-index: -1;
    filter: blur(20px);
    opacity: 0.4;
    transition: all 0.4s;
    animation: glow-pulse 3s infinite;
  }

  @keyframes glow-pulse {
    0% { transform: translate(-50%, -50%) scale(1); opacity: 0.4; }
    50% { transform: translate(-50%, -50%) scale(1.1); opacity: 0.6; }
    100% { transform: translate(-50%, -50%) scale(1); opacity: 0.4; }
  }

  .btn-primary.glow:hover::after {
    opacity: 0.8;
    filter: blur(30px);
  }

  .badge {
      display: inline-block;
      padding: 6px 16px;
      background: rgba(99, 102, 241, 0.15);
      border: 1px solid rgba(99, 102, 241, 0.3);
      border-radius: 100px;
      color: var(--primary);
      font-size: 13px;
      font-weight: 700;
      margin-bottom: 24px;
      animation: badge-breathe 4s infinite;
  }

  @keyframes badge-breathe {
      0% { box-shadow: 0 0 0 0 rgba(99, 102, 241, 0); }
      50% { box-shadow: 0 0 15px 0 rgba(99, 102, 241, 0.2); }
      100% { box-shadow: 0 0 0 0 rgba(99, 102, 241, 0); }
  }

  .quick-start {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 60px;
      padding: 60px;
      border-radius: 32px;
      align-items: center;
  }

  @media (max-width: 968px) {
      .quick-start { grid-template-columns: 1fr; padding: 40px; }
  }

  .step-list { list-style: none; }
  .step-list li { margin-bottom: 20px; font-weight: 600; display: flex; align-items: center; gap: 16px; }
  .step-num { 
      width: 28px; height: 28px; 
      background: var(--primary); 
      border-radius: 50%; 
      display: flex; 
      align-items: center; 
      justify-content: center; 
      font-size: 14px; 
      color: white; 
  }

  .quick-start-terminal {
      background: #000;
      border-radius: 16px;
      overflow: hidden;
      border: 1px solid var(--glass-border);
      box-shadow: 0 30px 60px -12px rgba(0,0,0,0.5);
  }

  .terminal-header {
      background: rgba(255,255,255,0.05);
      padding: 10px 20px;
      font-family: monospace;
      font-size: 12px;
      border-bottom: 1px solid var(--glass-border);
      color: var(--text-muted);
  }

  .terminal-body {
      padding: 24px;
      font-family: 'Fira Code', monospace;
      font-size: 14px;
      line-height: 1.8;
  }

  .prompt { color: var(--primary); margin-right: 12px; }
  .success { color: #34d399; margin-top: 12px; font-weight: 600; }

  /* Mobile Improvements */
  .mobile-toggle { 
    display: none; 
    background: rgba(255,255,255,0.05); 
    border: 1px solid var(--glass-border); 
    padding: 10px;
    border-radius: 12px;
    color: white; 
    cursor: pointer; 
  }
  
  @media (max-width: 968px) {
    .hero { grid-template-columns: 1fr; text-align: center; }
    .hero p { margin: 0 auto 40px; }
    .hero-actions { justify-content: center; }
    .docs-page { grid-template-columns: 1fr; }
    .docs-sidebar { 
        display: none; 
        position: fixed; top: 0; left: 0; width: 100%; height: 100%; 
        background: var(--bg); z-index: 2000; padding: 100px 40px;
    }
    .docs-sidebar.open { display: block; }
    .mobile-toggle { display: block; }
    .nav-links { display: none; }
  }

  /* Benchmarks */
  .bench-grid { display: grid; grid-template-columns: 2fr 1fr; gap: 32px; }
  .bench-card { padding: 40px; }
  .bench-card h3 { margin-bottom: 24px; font-size: 20px; }
  
  .chart { display: flex; flex-direction: column; gap: 20px; }
  .bar-group { display: flex; align-items: center; gap: 16px; }
  .bar-label { width: 80px; font-size: 14px; font-weight: 600; }
  .bar-wrapper { flex: 1; background: rgba(255,255,255,0.05); height: 12px; border-radius: 6px; overflow: hidden; }
  .bar { height: 100%; background: var(--text-muted); opacity: 0.5; border-radius: 6px; }
  .bar.primary { background: var(--primary); opacity: 1; box-shadow: 0 0 10px var(--primary-glow); }
  .bar-value { width: 100px; font-size: 14px; font-family: monospace; text-align: right; }

  .stat-large { font-size: 64px; font-weight: 800; color: white; }
  .stat-large .unit { font-size: 24px; color: var(--text-muted); }

  /* Community */
  .community-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 32px; }
  .comm-card { 
      padding: 48px; text-decoration: none; transition: all 0.4s;
      display: flex; flex-direction: column; align-items: center; text-align: center;
  }
  .comm-card:hover { transform: translateY(-8px); border-color: var(--primary); background: rgba(99, 102, 241, 0.05); }
  .comm-card .icon { font-size: 40px; margin-bottom: 24px; }
  .comm-card h3 { margin-bottom: 12px; }

  /* Footer */
  .site-footer {
      margin-top: 100px;
      padding: 80px 0 40px;
      background: rgba(15, 23, 42, 0.5);
      border-top: 1px solid var(--glass-border);
      backdrop-filter: blur(10px);
  }
  .footer-content { display: grid; grid-template-columns: 1fr 2fr; gap: 80px; margin-bottom: 60px; }
  .footer-brand .logo { font-size: 32px; margin-bottom: 16px; }
  .footer-brand p { color: var(--text-muted); }

  .footer-links { display: grid; grid-template-columns: repeat(3, 1fr); gap: 40px; }
  .footer-links h4 { font-size: 14px; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 24px; color: white; }
  .footer-links ul { list-style: none; }
  .footer-links li { margin-bottom: 12px; }
  .footer-links a { color: var(--text-muted); text-decoration: none; font-size: 14px; transition: 0.2s; }
  .footer-links a:hover { color: white; }

  .footer-bottom { 
      padding-top: 40px; border-top: 1px solid var(--glass-border);
      text-align: center; color: var(--text-muted); font-size: 14px;
  }

  @media (max-width: 968px) {
      .bench-grid, .community-grid, .footer-content { grid-template-columns: 1fr; gap: 40px; }
      .footer-links { grid-template-columns: repeat(2, 1fr); }
  }
</style>
