var Bt=Object.defineProperty;var Ut=(e,t,l)=>t in e?Bt(e,t,{enumerable:!0,configurable:!0,writable:!0,value:l}):e[t]=l;var Fe=(e,t,l)=>Ut(e,typeof t!="symbol"?t+"":t,l);(function(){const t=document.createElement("link").relList;if(t&&t.supports&&t.supports("modulepreload"))return;for(const r of document.querySelectorAll('link[rel="modulepreload"]'))a(r);new MutationObserver(r=>{for(const c of r)if(c.type==="childList")for(const p of c.addedNodes)p.tagName==="LINK"&&p.rel==="modulepreload"&&a(p)}).observe(document,{childList:!0,subtree:!0});function l(r){const c={};return r.integrity&&(c.integrity=r.integrity),r.referrerPolicy&&(c.referrerPolicy=r.referrerPolicy),r.crossOrigin==="use-credentials"?c.credentials="include":r.crossOrigin==="anonymous"?c.credentials="omit":c.credentials="same-origin",c}function a(r){if(r.ep)return;r.ep=!0;const c=l(r);fetch(r.href,c)}})();function fe(){}function Et(e){return e()}function bt(){return Object.create(null)}function me(e){e.forEach(Et)}function Ot(e){return typeof e=="function"}function jt(e,t){return e!=e?t==t:e!==t||e&&typeof e=="object"||typeof e=="function"}function Vt(e){return Object.keys(e).length===0}function s(e,t){e.appendChild(t)}function P(e,t,l){e.insertBefore(t,l||null)}function S(e){e.parentNode&&e.parentNode.removeChild(e)}function ze(e,t){for(let l=0;l<e.length;l+=1)e[l]&&e[l].d(t)}function i(e){return document.createElement(e)}function m(e){return document.createTextNode(e)}function h(){return m(" ")}function G(e,t,l,a){return e.addEventListener(t,l,a),()=>e.removeEventListener(t,l,a)}function Le(e){return function(t){return t.preventDefault(),e.call(this,t)}}function n(e,t,l){l==null?e.removeAttribute(t):e.getAttribute(t)!==l&&e.setAttribute(t,l)}function zt(e){return Array.from(e.childNodes)}function de(e,t){t=""+t,e.data!==t&&(e.data=t)}function qt(e,t){e.value=t??""}function T(e,t,l,a){l==null?e.style.removeProperty(t):e.style.setProperty(t,l,"")}function te(e,t,l){e.classList.toggle(t,!!l)}let Te;function Re(e){Te=e}function Gt(){if(!Te)throw new Error("Function called outside component initialization");return Te}function Ft(e){Gt().$$.on_mount.push(e)}const ye=[],_t=[];let we=[];const yt=[],Wt=Promise.resolve();let Qe=!1;function Qt(){Qe||(Qe=!0,Wt.then($t))}function Ke(e){we.push(e)}const We=new Set;let _e=0;function $t(){if(_e!==0)return;const e=Te;do{try{for(;_e<ye.length;){const t=ye[_e];_e++,Re(t),Kt(t.$$)}}catch(t){throw ye.length=0,_e=0,t}for(Re(null),ye.length=0,_e=0;_t.length;)_t.pop()();for(let t=0;t<we.length;t+=1){const l=we[t];We.has(l)||(We.add(l),l())}we.length=0}while(ye.length);for(;yt.length;)yt.pop()();Qe=!1,We.clear(),Re(e)}function Kt(e){if(e.fragment!==null){e.update(),me(e.before_update);const t=e.dirty;e.dirty=[-1],e.fragment&&e.fragment.p(e.ctx,t),e.after_update.forEach(Ke)}}function Jt(e){const t=[],l=[];we.forEach(a=>e.indexOf(a)===-1?t.push(a):l.push(a)),l.forEach(a=>a()),we=t}const Xt=new Set;function Yt(e,t){e&&e.i&&(Xt.delete(e),e.i(t))}function ve(e){return(e==null?void 0:e.length)!==void 0?e:Array.from(e)}function Zt(e,t,l){const{fragment:a,after_update:r}=e.$$;a&&a.m(t,l),Ke(()=>{const c=e.$$.on_mount.map(Et).filter(Ot);e.$$.on_destroy?e.$$.on_destroy.push(...c):me(c),e.$$.on_mount=[]}),r.forEach(Ke)}function es(e,t){const l=e.$$;l.fragment!==null&&(Jt(l.after_update),me(l.on_destroy),l.fragment&&l.fragment.d(t),l.on_destroy=l.fragment=null,l.ctx=[])}function ts(e,t){e.$$.dirty[0]===-1&&(ye.push(e),Qt(),e.$$.dirty.fill(0)),e.$$.dirty[t/31|0]|=1<<t%31}function ss(e,t,l,a,r,c,p=null,q=[-1]){const g=Te;Re(e);const o=e.$$={fragment:null,ctx:[],props:c,update:fe,not_equal:r,bound:bt(),on_mount:[],on_destroy:[],on_disconnect:[],before_update:[],after_update:[],context:new Map(t.context||(g?g.$$.context:[])),callbacks:bt(),dirty:q,skip_bound:!1,root:t.target||g.$$.root};p&&p(o.root);let d=!1;if(o.ctx=l?l(e,t.props||{},(k,v,...C)=>{const D=C.length?C[0]:v;return o.ctx&&r(o.ctx[k],o.ctx[k]=D)&&(!o.skip_bound&&o.bound[k]&&o.bound[k](D),d&&ts(e,k)),v}):[],o.update(),d=!0,me(o.before_update),o.fragment=a?a(o.ctx):!1,t.target){if(t.hydrate){const k=zt(t.target);o.fragment&&o.fragment.l(k),k.forEach(S)}else o.fragment&&o.fragment.c();t.intro&&Yt(e.$$.fragment),Zt(e,t.target,t.anchor),$t()}Re(g)}class ls{constructor(){Fe(this,"$$");Fe(this,"$$set")}$destroy(){es(this,1),this.$destroy=fe}$on(t,l){if(!Ot(l))return fe;const a=this.$$.callbacks[t]||(this.$$.callbacks[t]=[]);return a.push(l),()=>{const r=a.indexOf(l);r!==-1&&a.splice(r,1)}}$set(t){this.$$set&&!Vt(t)&&(this.$$.skip_bound=!0,this.$$set(t),this.$$.skip_bound=!1)}}const ns="4";typeof window<"u"&&(window.__svelte||(window.__svelte={v:new Set})).v.add(ns);const Ve=[{id:"getting-started",title:"Getting Started",sections:[{id:"introduction",title:"Introduction",content:`kronix is a high-performance, architecturally hardened web framework for the Dart ecosystem. It is designed for developers who require a structured, batteries-included environment for building scalable APIs.

### Core Philosophy
kronix draws inspiration from established patterns found in Laravel and NestJS, bringing type-safe dependency injection, fluent database interactions, and a declarative validation system to the Dart backend.

### Key Benefits
- **Deterministic Lifecycle**: Predictable resource cleanup and socket management.
* **Type-Safe DI**: Hierarchical containers prevent state leakage.
* **Production Ready**: Built-in micro-benchmarking and structured logging.
* **V0.2.0 "Venom"**: Now with Native ORM Relationships and Unified Caching.`},{id:"installation",title:"Installation",content:`To get started with kronix, you need to install the CLI tool globally or run it via the Dart SDK.

### Using the CLI
The fastest way to start is using the scaffold command:

\`\`\`bash
# Create a new project
dart run bin/kronix.dart create my_api

# Navigate into project
cd my_api

# Install dependencies
dart pub get
\`\`\`

### Requirements
- Dart SDK 3.0.0 or higher
- PostgreSQL (for the ORM features)
- Redis (Optional, for Redis Cache driver)`}]},{id:"core-concepts",title:"Core Concepts",sections:[{id:"routing",title:"Routing & Groups",content:`kronix uses a high-performance Trie-based router. This ensures that route matching remains O(n) relative to path segments, not total route count.

### Basic Routing
\`\`\`dart
final app = App();

app.get('/welcome', (ctx) async {
  return ctx.text('Hello World');
});
\`\`\`

### Pre-compiled Pipelines
In v0.2.0, kronix automatically pre-compiles your middleware chains during server startup. This eliminates the overhead of building the execution stack for every request, resulting in extreme throughput.

### Route Groups
Groups allow you to apply middleware and path prefixes to multiple routes at once.

\`\`\`dart
app.group('/api/v1', middleware: [AuthMiddleware()], callback: (router) {
  router.get('/profile', (ctx) async {
    return ctx.json(ctx.user);
  });
});
\`\`\`

### Named Parameters
Extract values directly from the URL.

\`\`\`dart
app.get('/users/:id', (ctx) async {
  final userId = ctx.params['id'];
  return ctx.json({'userId': userId});
});
\`\`\``},{id:"dependency-injection",title:"Dependency Injection",content:`The DI system in kronix is hierarchical. There is a global container for singletons and request-specific child containers for scoped services.

### Registration
\`\`\`dart
// Global singleton
di.singleton(PaymentService());

// Request-scoped factory
di.scoped((container) => UserSession());
\`\`\`

### Resolution
Services can be resolved from the global \`di\` or the request \`ctx\`.

\`\`\`dart
app.get('/pay', (ctx) async {
  final session = ctx.resolve<UserSession>();
  final billing = ctx.resolve<PaymentService>();
});
\`\`\`

### Resource Disposal
Any service implementing the \`Disposable\` interface will be automatically cleaned up when the request lifecycle ends.`}]},{id:"data-layer",title:"Database & ORM",sections:[{id:"query-builder",title:"Query Builder",content:`kronix features a fluent Query Builder that makes working with PostgreSQL intuitive and type-safe.

### Basic Queries
\`\`\`dart
final users = await db.table('users')
    .where('active', '=', true)
    .orderBy('created_at', 'DESC')
    .get();
\`\`\`

### Automatic Transactions
Atomicity is built-in. Use the \`transaction\` wrapper to ensure your database operations either all succeed or all fail.

\`\`\`dart
await db.transaction((tx) async {
  await tx.table('orders').insert(data);
  await tx.table('inventory').decrement('stock');
});
\`\`\``},{id:"orm-relationships",title:"ORM Relationships",content:`Kronix ORM supports native relationships, allowing you to traverse your database naturally.

### Defining Relationships
\`\`\`dart
class User extends Model {
  @override String get tableName => 'users';

  // Has Many
  Future<List<Post>> posts() => hasMany<Post>(Post.fromRow);

  // Has One
  Future<Profile?> profile() => hasOne<Profile>(Profile.fromRow);
}

class Post extends Model {
  @override String get tableName => 'posts';

  // Belongs To
  Future<User?> author() => belongsTo<User>(User.fromRow);
}
\`\`\`

### Usage
\`\`\`dart
final user = await User.query().find(1);
final posts = await user.posts(); // Resolves relationships
\`\`\``}]},{id:"services",title:"Services & Auth",sections:[{id:"caching",title:"Unified Caching",content:`The \`Cache\` facade provides a consistent API for temporary data storage across multiple drivers.

### Configuration
Set \`CACHE_DRIVER=redis\` or \`CACHE_DRIVER=memory\` in your \`.env\`.

### Fluent API
\`\`\`dart
// Basic get/set
await Cache.put('key', 'value', Duration(minutes: 10));
final val = await Cache.get('key');

// The "Remember" Pattern
final userCount = await Cache.remember('users.count', Duration(hour: 1), () async {
    return await User.query().count();
});
\`\`\``},{id:"sessions",title:"Native Sessions",content:`Kronix provides server-side sessions managed via cookies.

### Setup
Add the \`SessionMiddleware\` to your app globally or to specific groups.

\`\`\`dart
app.use(SessionMiddleware());

app.get('/dashboard', (ctx) async {
  final session = ctx.session;
  session.set('last_visit', DateTime.now().toString());
  
  return ctx.text('Welcome back!');
});
\`\`\`

By default, sessions are stored in memory but can be persisted to Redis for distributed environments.`},{id:"validation",title:"Validation Engine",content:`Validation in kronix is declarative and extremely fast (~3.6µs per object).

### Inline Validation
\`\`\`dart
app.post('/register', (ctx) async {
  final data = await ctx.validate({
    'email': 'required|email',
    'password': 'required|min:8',
    'age': 'numeric|min:18',
  });
});
\`\`\`

### Complex Data
Supports nested arrays and wildcard validation:
\`\`\`dart
'items.*.id': 'required|numeric',
'items.*.qty': 'required|min:1',
\`\`\``}]},{id:"advanced",title:"Advanced & CLI",sections:[{id:"cli-tool",title:"CLI Scaffolding 2.0",content:"The `kronix` CLI is your primary tool for rapid development.\n\n### Automated Migrations\nWhen creating a model, you can automatically generate a migration file:\n\n```bash\nkronix make:model Product -m\n```\n\nThis creates:\n1. `lib/models/product.dart`\n2. `lib/database/migrations/[timestamp]_create_products_table.dart`\n\n### Watch Mode\nRebuild and restart your server automatically on file changes:\n```bash\nkronix watch\n```\n\n### Production Build\n```bash\nkronix build\n```"},{id:"security-harden",title:"Security Hardening",content:`Kronix includes built-in protections against common web vulnerabilities.

### Payload Size Limits
Global enforcement of \`MAX_BODY_SIZE\` prevents OOM attacks from massive request bodies.

### Backpressure Control
Configure \`MAX_CONCURRENT_REQUESTS\` to gracefully reject traffic with a 503 response when the server is under extreme load.

### Case-Insensitive Headers
Seamless header handling ensures your middleware works regardless of client implementation (e.g., \`Authorization\` vs \`authorization\`).`}]}];function wt(e,t,l){const a=e.slice();return a[30]=t[l],a}function kt(e,t,l){const a=e.slice();return a[33]=t[l],a}function xt(e,t,l){const a=e.slice();return a[36]=t[l],a}function Ct(e,t,l){const a=e.slice();return a[27]=t[l],a}function is(e){let t,l,a,r,c,p,q,g,o,d,k,v=e[2].title+"",C,D,J=e[0].title+"",M,X,$,ne=e[0].title+"",F,u,E,Y=At(e[0].content)+"",se,W,I,Z,Q,H,y,x,ae,ie,j,L,R,b,w,ee=ve(e[6]),N=[];for(let f=0;f<ee.length;f+=1)N[f]=Rt(kt(e,ee,f));let A=null;ee.length||(A=St());function ke(f,O){return f[8]?rs:os}let re=ke(e),le=re(e),V=e[7]&&Tt(e),ce=ve(e[0].content.matchAll(/^#+ (.*)/gm)),B=[];for(let f=0;f<ce.length;f+=1)B[f]=Pt(wt(e,ce,f));return{c(){t=i("div"),l=i("aside"),a=i("div"),r=i("input"),c=h(),p=i("div");for(let f=0;f<N.length;f+=1)N[f].c();A&&A.c(),q=h(),g=i("main"),o=i("div"),d=i("div"),k=m("Documentation / "),C=m(v),D=m(" / "),M=m(J),X=h(),$=i("h1"),F=m(ne),u=h(),E=i("div"),se=h(),W=i("div"),I=i("div"),le.c(),Z=h(),V&&V.c(),Q=h(),H=i("button"),H.textContent="← Back Home",y=h(),x=i("aside"),ae=i("div"),ie=i("h5"),ie.textContent="On this page",j=h(),L=i("nav"),R=i("ul");for(let f=0;f<B.length;f+=1)B[f].c();n(r,"type","text"),n(r,"placeholder","Search docs..."),n(r,"class","svelte-e0548q"),n(a,"class","sidebar-search svelte-e0548q"),n(p,"class","sidebar-content svelte-e0548q"),n(l,"class","docs-sidebar svelte-e0548q"),te(l,"open",e[3]),n(d,"class","breadcrumb svelte-e0548q"),n($,"class","docs-title svelte-e0548q"),n(E,"class","rendered-content"),n(I,"class","nav-btns svelte-e0548q"),n(H,"class","btn-secondary svelte-e0548q"),T(H,"margin-top","40px"),T(H,"width","100%"),n(W,"class","pagination svelte-e0548q"),n(o,"class","docs-inner svelte-e0548q"),n(g,"class","docs-main-content svelte-e0548q"),n(ie,"class","svelte-e0548q"),n(R,"class","svelte-e0548q"),n(ae,"class","right-sidebar-content svelte-e0548q"),n(x,"class","docs-right-sidebar desktop-only svelte-e0548q"),n(t,"class","docs-page container animate-fade-in svelte-e0548q")},m(f,O){P(f,t,O),s(t,l),s(l,a),s(a,r),qt(r,e[1]),s(l,c),s(l,p);for(let _=0;_<N.length;_+=1)N[_]&&N[_].m(p,null);A&&A.m(p,null),s(t,q),s(t,g),s(g,o),s(o,d),s(d,k),s(d,C),s(d,D),s(d,M),s(o,X),s(o,$),s($,F),s(o,u),s(o,E),E.innerHTML=Y,s(o,se),s(o,W),s(W,I),le.m(I,null),s(I,Z),V&&V.m(I,null),s(W,Q),s(W,H),s(t,y),s(t,x),s(x,ae),s(ae,ie),s(ae,j),s(ae,L),s(L,R);for(let _=0;_<B.length;_+=1)B[_]&&B[_].m(R,null);b||(w=[G(r,"input",e[22]),G(H,"click",e[10])],b=!0)},p(f,O){if(O[0]&2&&r.value!==f[1]&&qt(r,f[1]),O[0]&577){ee=ve(f[6]);let _;for(_=0;_<ee.length;_+=1){const ue=kt(f,ee,_);N[_]?N[_].p(ue,O):(N[_]=Rt(ue),N[_].c(),N[_].m(p,null))}for(;_<N.length;_+=1)N[_].d(1);N.length=ee.length,!ee.length&&A?A.p(f,O):ee.length?A&&(A.d(1),A=null):(A=St(),A.c(),A.m(p,null))}if(O[0]&8&&te(l,"open",f[3]),O[0]&4&&v!==(v=f[2].title+"")&&de(C,v),O[0]&1&&J!==(J=f[0].title+"")&&de(M,J),O[0]&1&&ne!==(ne=f[0].title+"")&&de(F,ne),O[0]&1&&Y!==(Y=At(f[0].content)+"")&&(E.innerHTML=Y),re===(re=ke(f))&&le?le.p(f,O):(le.d(1),le=re(f),le&&(le.c(),le.m(I,Z))),f[7]?V?V.p(f,O):(V=Tt(f),V.c(),V.m(I,null)):V&&(V.d(1),V=null),O[0]&1){ce=ve(f[0].content.matchAll(/^#+ (.*)/gm));let _;for(_=0;_<ce.length;_+=1){const ue=wt(f,ce,_);B[_]?B[_].p(ue,O):(B[_]=Pt(ue),B[_].c(),B[_].m(R,null))}for(;_<B.length;_+=1)B[_].d(1);B.length=ce.length}},d(f){f&&S(t),ze(N,f),A&&A.d(),le.d(),V&&V.d(),ze(B,f),b=!1,me(w)}}}function as(e){let t,l,a,r,c,p,q,g,o,d,k,v,C,D,J,M,X,$,ne,F,u,E,Y,se,W,I,Z,Q,H,y,x,ae="{",ie,j,L,R,b,w,ee,N,A,ke,re,le,V="{",ce,B,f,O,_,ue,Pe,Je,Me,Xe,Ie,Ye,De,Ze,Ae,et,Ee,tt,Oe,st,$e,lt,Ht="}",nt,it,He,at,Ne,ot,Be,rt,Nt="}",ct,dt,pe,Ue,ut,xe,pt,Ce,vt,ge,oe,Se,ft,be,ht,he,Ge,mt,qe=ve(e[11]),K=[];for(let z=0;z<qe.length;z+=1)K[z]=Mt(Ct(e,qe,z));return{c(){t=i("main"),l=i("section"),a=i("div"),r=i("div"),r.textContent='v0.2.0 "Venom" Released',c=h(),p=i("h1"),p.innerHTML='Architect <br/><span class="gradient-text">Hardened</span> APIs',q=h(),g=i("p"),g.textContent="The enterprise-grade backend framework for Dart. Built-in DI, ORM, and Validation for developers who don't compromise on architecture.",o=h(),d=i("div"),d.innerHTML='<div class="mouse svelte-e0548q"></div> <span>Scroll to explore</span>',k=h(),v=i("div"),C=i("button"),C.textContent="Read the Docs",D=h(),J=i("button"),J.textContent="View Benchmarks",M=h(),X=i("div"),$=i("div"),$.innerHTML='<div class="dot red"></div><div class="dot yellow"></div><div class="dot green"></div> <span class="file-name">main.dart</span>',ne=h(),F=i("pre"),u=i("code"),E=i("span"),E.textContent="import",Y=m(" "),se=i("span"),se.textContent="'package:kronix/kronix.dart'",W=m(`;\r
\r
`),I=i("span"),I.textContent="void",Z=m(" "),Q=i("span"),Q.textContent="main",H=m("() "),y=i("span"),y.textContent="async",x=m(" "),ie=m(ae),j=m(`\r
  `),L=i("span"),L.textContent="final",R=m(" app = "),b=i("span"),b.textContent="App",w=m(`();\r
\r
  app.`),ee=i("span"),ee.textContent="get",N=m("("),A=i("span"),A.textContent="'/orders/:id'",ke=m(", (ctx) "),re=i("span"),re.textContent="async",le=m(" "),ce=m(V),B=m(`\r
    `),f=i("span"),f.textContent="final",O=m(" db = ctx."),_=i("span"),_.textContent="resolve",ue=m("<"),Pe=i("span"),Pe.textContent="Database",Je=m(`>();\r
    `),Me=i("span"),Me.textContent="return",Xe=m(" ctx."),Ie=i("span"),Ie.textContent="json",Ye=m(`(\r
      `),De=i("span"),De.textContent="await",Ze=m(" db."),Ae=i("span"),Ae.textContent="table",et=m("("),Ee=i("span"),Ee.textContent="'orders'",tt=m(")."),Oe=i("span"),Oe.textContent="find",st=m("(ctx.params["),$e=i("span"),$e.textContent="'id'",lt=m(`])\r
    );\r
  `),nt=m(Ht),it=m(`);\r
\r
  `),He=i("span"),He.textContent="await",at=m(" app."),Ne=i("span"),Ne.textContent="listen",ot=m("(port: "),Be=i("span"),Be.textContent="8080",rt=m(`);\r
`),ct=m(Nt),dt=h(),pe=i("section"),Ue=i("h2"),Ue.innerHTML='Built for <span class="gradient-text">Performance</span>',ut=h(),xe=i("div");for(let z=0;z<K.length;z+=1)K[z].c();pt=h(),Ce=i("section"),Ce.innerHTML='<div class="glass quick-start svelte-e0548q"><div class="quick-start-info"><h2 style="font-size: 36px; margin-bottom: 20px;">Quick <span class="gradient-text">Start</span></h2> <p style="color: var(--text-muted); margin-bottom: 30px;">Get your API up and running in less than 60 seconds.</p> <ul class="step-list svelte-e0548q"><li class="svelte-e0548q"><span class="step-num svelte-e0548q">1</span> Global Install</li> <li class="svelte-e0548q"><span class="step-num svelte-e0548q">2</span> Project Scaffold</li> <li class="svelte-e0548q"><span class="step-num svelte-e0548q">3</span> Live Development</li></ul></div> <div class="quick-start-terminal svelte-e0548q"><div class="terminal-header svelte-e0548q"><span>bash</span></div> <div class="terminal-body svelte-e0548q"><p><span class="prompt svelte-e0548q">$</span> dart pub global activate kronix</p> <p><span class="prompt svelte-e0548q">$</span> kronix create my_api</p> <p><span class="prompt svelte-e0548q">$</span> cd my_api &amp;&amp; kronix make:model User -m</p> <p class="success svelte-e0548q">🚀 Server ready on http://0.0.0.0:3000</p></div></div></div>',vt=h(),ge=i("section"),oe=i("div"),Se=i("h2"),Se.textContent="Ready to build?",ft=h(),be=i("p"),be.textContent="Join thousands of developers building the next generation of APIs.",ht=h(),he=i("button"),he.textContent="Start Free Today",n(r,"class","badge svelte-e0548q"),n(p,"class","hero-title svelte-e0548q"),n(g,"class","hero-subtitle svelte-e0548q"),n(d,"class","scroll-indicator svelte-e0548q"),n(C,"class","btn-primary svelte-e0548q"),n(J,"class","btn-secondary svelte-e0548q"),n(v,"class","hero-actions svelte-e0548q"),n(a,"class","hero-content"),n($,"class","window-header"),n(E,"class","keyword svelte-e0548q"),n(se,"class","string svelte-e0548q"),n(I,"class","keyword svelte-e0548q"),n(Q,"class","function svelte-e0548q"),n(y,"class","keyword svelte-e0548q"),n(L,"class","keyword svelte-e0548q"),n(b,"class","class svelte-e0548q"),n(ee,"class","function svelte-e0548q"),n(A,"class","string svelte-e0548q"),n(re,"class","keyword svelte-e0548q"),n(f,"class","keyword svelte-e0548q"),n(_,"class","function svelte-e0548q"),n(Pe,"class","class svelte-e0548q"),n(Me,"class","keyword svelte-e0548q"),n(Ie,"class","function svelte-e0548q"),n(De,"class","keyword svelte-e0548q"),n(Ae,"class","function svelte-e0548q"),n(Ee,"class","string svelte-e0548q"),n(Oe,"class","function svelte-e0548q"),n($e,"class","string svelte-e0548q"),n(He,"class","keyword svelte-e0548q"),n(Ne,"class","function svelte-e0548q"),n(Be,"class","number svelte-e0548q"),n(X,"class","hero-image glass svelte-e0548q"),n(l,"class","hero container svelte-e0548q"),n(Ue,"class","section-title svelte-e0548q"),n(xe,"class","features-grid svelte-e0548q"),n(pe,"id","features"),n(pe,"class","container svelte-e0548q"),T(pe,"padding","100px 0"),n(Ce,"class","container svelte-e0548q"),T(Ce,"padding","100px 0"),T(Se,"font-size","42px"),T(Se,"margin-bottom","20px"),T(be,"color","var(--text-muted)"),T(be,"margin-bottom","40px"),T(be,"font-size","18px"),n(he,"class","btn-primary glow svelte-e0548q"),T(he,"padding","16px 48px"),T(he,"font-size","18px"),n(oe,"class","glass"),T(oe,"padding","80px"),T(oe,"border-radius","32px"),n(ge,"class","container svelte-e0548q"),T(ge,"text-align","center"),T(ge,"padding-bottom","150px"),n(t,"class","animate-fade-in")},m(z,je){P(z,t,je),s(t,l),s(l,a),s(a,r),s(a,c),s(a,p),s(a,q),s(a,g),s(a,o),s(a,d),s(a,k),s(a,v),s(v,C),s(v,D),s(v,J),s(l,M),s(l,X),s(X,$),s(X,ne),s(X,F),s(F,u),s(u,E),s(u,Y),s(u,se),s(u,W),s(u,I),s(u,Z),s(u,Q),s(u,H),s(u,y),s(u,x),s(u,ie),s(u,j),s(u,L),s(u,R),s(u,b),s(u,w),s(u,ee),s(u,N),s(u,A),s(u,ke),s(u,re),s(u,le),s(u,ce),s(u,B),s(u,f),s(u,O),s(u,_),s(u,ue),s(u,Pe),s(u,Je),s(u,Me),s(u,Xe),s(u,Ie),s(u,Ye),s(u,De),s(u,Ze),s(u,Ae),s(u,et),s(u,Ee),s(u,tt),s(u,Oe),s(u,st),s(u,$e),s(u,lt),s(u,nt),s(u,it),s(u,He),s(u,at),s(u,Ne),s(u,ot),s(u,Be),s(u,rt),s(u,ct),s(t,dt),s(t,pe),s(pe,Ue),s(pe,ut),s(pe,xe);for(let U=0;U<K.length;U+=1)K[U]&&K[U].m(xe,null);s(t,pt),s(t,Ce),s(t,vt),s(t,ge),s(ge,oe),s(oe,Se),s(oe,ft),s(oe,be),s(oe,ht),s(oe,he),Ge||(mt=[G(C,"click",e[20]),G(he,"click",e[21])],Ge=!0)},p(z,je){if(je[0]&2048){qe=ve(z[11]);let U;for(U=0;U<qe.length;U+=1){const gt=Ct(z,qe,U);K[U]?K[U].p(gt,je):(K[U]=Mt(gt),K[U].c(),K[U].m(xe,null))}for(;U<K.length;U+=1)K[U].d(1);K.length=qe.length}},d(z){z&&S(t),ze(K,z),Ge=!1,me(mt)}}}function St(e){let t;return{c(){t=i("p"),t.textContent="No results found.",T(t,"padding","20px"),T(t,"color","var(--text-muted)"),T(t,"font-size","14px")},m(l,a){P(l,t,a)},p:fe,d(l){l&&S(t)}}}function Lt(e){let t,l,a=e[36].title+"",r,c,p,q;function g(){return e[23](e[33],e[36])}return{c(){t=i("li"),l=i("button"),r=m(a),c=h(),n(l,"class","svelte-e0548q"),te(l,"active",e[0].id===e[36].id)},m(o,d){P(o,t,d),s(t,l),s(l,r),s(t,c),p||(q=G(l,"click",g),p=!0)},p(o,d){e=o,d[0]&64&&a!==(a=e[36].title+"")&&de(r,a),d[0]&65&&te(l,"active",e[0].id===e[36].id)},d(o){o&&S(t),p=!1,q()}}}function Rt(e){let t,l,a=e[33].title+"",r,c,p,q,g=ve(e[33].sections),o=[];for(let d=0;d<g.length;d+=1)o[d]=Lt(xt(e,g,d));return{c(){t=i("div"),l=i("h4"),r=m(a),c=h(),p=i("ul");for(let d=0;d<o.length;d+=1)o[d].c();q=h(),n(l,"class","svelte-e0548q"),n(p,"class","svelte-e0548q"),n(t,"class","sidebar-category svelte-e0548q")},m(d,k){P(d,t,k),s(t,l),s(l,r),s(t,c),s(t,p);for(let v=0;v<o.length;v+=1)o[v]&&o[v].m(p,null);s(t,q)},p(d,k){if(k[0]&64&&a!==(a=d[33].title+"")&&de(r,a),k[0]&577){g=ve(d[33].sections);let v;for(v=0;v<g.length;v+=1){const C=xt(d,g,v);o[v]?o[v].p(C,k):(o[v]=Lt(C),o[v].c(),o[v].m(p,null))}for(;v<o.length;v+=1)o[v].d(1);o.length=g.length}},d(d){d&&S(t),ze(o,d)}}}function os(e){let t;return{c(){t=i("div")},m(l,a){P(l,t,a)},p:fe,d(l){l&&S(t)}}}function rs(e){let t,l,a,r,c=e[8].title+"",p,q,g;return{c(){t=i("button"),l=i("span"),l.textContent="Previous",a=h(),r=i("span"),p=m(c),n(l,"class","label svelte-e0548q"),n(r,"class","title svelte-e0548q"),n(t,"class","nav-btn prev svelte-e0548q")},m(o,d){P(o,t,d),s(t,l),s(t,a),s(t,r),s(r,p),q||(g=G(t,"click",e[24]),q=!0)},p(o,d){d[0]&256&&c!==(c=o[8].title+"")&&de(p,c)},d(o){o&&S(t),q=!1,g()}}}function Tt(e){let t,l,a,r,c=e[7].title+"",p,q,g;return{c(){t=i("button"),l=i("span"),l.textContent="Next",a=h(),r=i("span"),p=m(c),n(l,"class","label svelte-e0548q"),n(r,"class","title svelte-e0548q"),n(t,"class","nav-btn next svelte-e0548q")},m(o,d){P(o,t,d),s(t,l),s(t,a),s(t,r),s(r,p),q||(g=G(t,"click",e[25]),q=!0)},p(o,d){d[0]&128&&c!==(c=o[7].title+"")&&de(p,c)},d(o){o&&S(t),q=!1,g()}}}function Pt(e){let t,l,a=e[30][1]+"",r,c,p,q;function g(){return e[26](e[30])}return{c(){t=i("li"),l=i("a"),r=m(a),n(l,"href",c="#"+e[30][1].toLowerCase().replace(/\s+/g,"-")),n(l,"class","svelte-e0548q"),n(t,"class","svelte-e0548q")},m(o,d){P(o,t,d),s(t,l),s(l,r),p||(q=G(l,"click",Le(g)),p=!0)},p(o,d){e=o,d[0]&1&&a!==(a=e[30][1]+"")&&de(r,a),d[0]&1&&c!==(c="#"+e[30][1].toLowerCase().replace(/\s+/g,"-"))&&n(l,"href",c)},d(o){o&&S(t),p=!1,q()}}}function Mt(e){let t,l,a,r,c,p,q;return{c(){t=i("div"),l=i("div"),l.textContent=`${e[27].icon}`,a=h(),r=i("h3"),r.textContent=`${e[27].title}`,c=h(),p=i("p"),p.textContent=`${e[27].desc}`,q=h(),n(l,"class","feature-icon svelte-e0548q"),n(r,"class","svelte-e0548q"),n(p,"class","svelte-e0548q"),n(t,"class","feature-card glass svelte-e0548q")},m(g,o){P(g,t,o),s(t,l),s(t,a),s(t,r),s(t,c),s(t,p),s(t,q)},p:fe,d(g){g&&S(t)}}}function It(e){let t;return{c(){t=i("div"),t.innerHTML='<h1 class="section-title svelte-e0548q">Performance <span class="gradient-text">Analysis</span></h1> <p style="text-align: center; color: var(--text-muted); margin-bottom: 60px; font-size: 18px;">Real-world micro-benchmarks conducted on the kronix core engine.</p> <div class="bench-grid svelte-e0548q"><div class="glass bench-card svelte-e0548q"><h3 class="svelte-e0548q">Internal Latency (µs)</h3> <p style="color: var(--text-muted); font-size: 14px; margin-bottom: 32px;">Lower is better. Measured per single operation overhead.</p> <div class="chart svelte-e0548q"><div class="bar-group svelte-e0548q"><div class="bar-label svelte-e0548q">Routing</div> <div class="bar-wrapper svelte-e0548q"><div class="bar primary svelte-e0548q" style="width: 24%"></div></div> <div class="bar-value svelte-e0548q">1.2 µs</div></div> <div class="bar-group svelte-e0548q"><div class="bar-label svelte-e0548q">Validation</div> <div class="bar-wrapper svelte-e0548q"><div class="bar primary svelte-e0548q" style="width: 72%"></div></div> <div class="bar-value svelte-e0548q">3.6 µs</div></div> <div class="bar-group svelte-e0548q"><div class="bar-label svelte-e0548q">DI Resolve</div> <div class="bar-wrapper svelte-e0548q"><div class="bar primary svelte-e0548q" style="width: 18%"></div></div> <div class="bar-value svelte-e0548q">0.9 µs</div></div></div></div> <div class="glass bench-card svelte-e0548q"><h3 class="svelte-e0548q">Requests / Sec</h3> <div class="stat-large svelte-e0548q">84.2<span class="unit svelte-e0548q">k</span></div> <p style="color: var(--text-muted); font-size: 14px; margin-top: 10px;">Throughput on M1 Max (Raw JSON)</p></div></div> <div class="tech-deep-dive" style="margin-top: 120px;"><h2 class="section-title svelte-e0548q">Framework <span class="gradient-text">DNA</span></h2> <div class="features-grid svelte-e0548q"><div class="glass feature-card svelte-e0548q"><span class="feature-icon svelte-e0548q">🌿</span> <h3 class="svelte-e0548q">Radix-Trie Router</h3> <p class="svelte-e0548q">O(n) matching complexity where &#39;n&#39; is path segments. Routing speed remains constant regardless of the number of registered routes (tested up to 10k routes).</p></div> <div class="glass feature-card svelte-e0548q"><span class="feature-icon svelte-e0548q">📦</span> <h3 class="svelte-e0548q">Scoped Container</h3> <p class="svelte-e0548q">Every request gets a dedicated child container. This ensures 100% isolation of stateful services like DB sessions and Auth contexts.</p></div> <div class="glass feature-card svelte-e0548q"><span class="feature-icon svelte-e0548q">♻️</span> <h3 class="svelte-e0548q">Disposable Pattern</h3> <p class="svelte-e0548q">Automatic resource cleanup. Services implementing &#39;Disposable&#39; are awaited and cleared before the response socket is released.</p></div></div></div>',n(t,"class","container animate-fade-in svelte-e0548q"),T(t,"padding","160px 0")},m(l,a){P(l,t,a)},d(l){l&&S(t)}}}function Dt(e){let t;return{c(){t=i("div"),t.innerHTML='<h1 class="section-title svelte-e0548q">Join the <span class="gradient-text">Ecosystem</span></h1> <div class="community-grid svelte-e0548q"><a href="#" class="glass comm-card svelte-e0548q"><div class="icon svelte-e0548q">💬</div> <h3 class="svelte-e0548q">Discord</h3> <p>Chat with the core team and fellow developers.</p></a> <a href="#" class="glass comm-card svelte-e0548q"><div class="icon svelte-e0548q">🐦</div> <h3 class="svelte-e0548q">Twitter</h3> <p>Get the latest news and ecosystem updates.</p></a> <a href="#" class="glass comm-card svelte-e0548q"><div class="icon svelte-e0548q">📖</div> <h3 class="svelte-e0548q">GitHub</h3> <p>Contribute to the core framework and plugins.</p></a></div>',n(t,"class","container animate-fade-in svelte-e0548q"),T(t,"padding","160px 0"),T(t,"text-align","center")},m(l,a){P(l,t,a)},d(l){l&&S(t)}}}function cs(e){let t,l,a,r,c,p,q,g,o,d,k,v,C,D,J,M,X,$,ne,F,u,E,Y=e[3]?"✕":"☰",se,W,I,Z,Q,H,y,x;function ae(b,w){return b[5]==="home"?as:is}let ie=ae(e),j=ie(e),L=e[5]==="benchmarks"&&It(),R=e[5]==="community"&&Dt();return{c(){t=i("div"),l=h(),a=i("div"),a.innerHTML='<div class="blob blob-1"></div> <div class="blob blob-2"></div> <div class="blob blob-3"></div>',r=h(),c=i("nav"),p=i("div"),q=i("div"),q.innerHTML='<span class="gradient-text">kronix</span>',g=h(),o=i("div"),d=i("a"),d.textContent="Features",k=h(),v=i("a"),v.textContent="Docs",C=h(),D=i("a"),D.textContent="Benchmarks",J=h(),M=i("a"),M.textContent="Community",X=h(),$=i("a"),$.innerHTML='<svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"></path></svg>',ne=h(),F=i("button"),F.textContent="Get Started",u=h(),E=i("button"),se=m(Y),W=h(),j.c(),I=h(),L&&L.c(),Z=h(),R&&R.c(),Q=h(),H=i("footer"),H.innerHTML='<div class="container footer-content svelte-e0548q"><div class="footer-brand svelte-e0548q"><div class="logo svelte-e0548q"><span class="gradient-text">kronix</span></div> <p class="svelte-e0548q">Architect hardened APIs with ease.</p></div> <div class="footer-links svelte-e0548q"><div><h4 class="svelte-e0548q">Resources</h4> <ul class="svelte-e0548q"><li class="svelte-e0548q"><a href="#/docs" class="svelte-e0548q">Documentation</a></li> <li class="svelte-e0548q"><a href="#/benchmarks" class="svelte-e0548q">Benchmarks</a></li> <li class="svelte-e0548q"><a href="#" class="svelte-e0548q">Showcase</a></li></ul></div> <div><h4 class="svelte-e0548q">Ecosystem</h4> <ul class="svelte-e0548q"><li class="svelte-e0548q"><a href="https://github.com" class="svelte-e0548q">GitHub</a></li> <li class="svelte-e0548q"><a href="#" class="svelte-e0548q">Plugins</a></li> <li class="svelte-e0548q"><a href="#" class="svelte-e0548q">CLI Tool</a></li></ul></div> <div><h4 class="svelte-e0548q">Legal</h4> <ul class="svelte-e0548q"><li class="svelte-e0548q"><a href="#" class="svelte-e0548q">Privacy</a></li> <li class="svelte-e0548q"><a href="#" class="svelte-e0548q">Terms</a></li> <li class="svelte-e0548q"><a href="#" class="svelte-e0548q">License</a></li></ul></div></div></div> <div class="container footer-bottom svelte-e0548q"><p>© 2026 kronix Framework. Built with ❤️ for the Dart community.</p></div>',n(t,"class","grid-background"),n(a,"class","bg-blobs"),n(q,"class","logo svelte-e0548q"),n(q,"role","button"),n(q,"tabindex","0"),T(q,"cursor","pointer"),n(d,"href","#features"),n(d,"class","svelte-e0548q"),te(d,"active",e[5]==="home"),n(v,"href","#/docs"),n(v,"class","svelte-e0548q"),te(v,"active",e[5]==="docs"),n(D,"href","#/benchmarks"),n(D,"class","svelte-e0548q"),te(D,"active",e[5]==="benchmarks"),n(M,"href","#/community"),n(M,"class","svelte-e0548q"),te(M,"active",e[5]==="community"),n($,"href","https://github.com/garv/kronix"),n($,"target","_blank"),n($,"class","github-link svelte-e0548q"),n(F,"class","btn-primary svelte-e0548q"),n(o,"class","nav-links svelte-e0548q"),n(E,"class","mobile-toggle svelte-e0548q"),n(E,"aria-label","Toggle Menu"),n(p,"class","container nav-content svelte-e0548q"),n(c,"class","navbar svelte-e0548q"),te(c,"scrolled",e[4]),n(H,"class","site-footer svelte-e0548q")},m(b,w){P(b,t,w),P(b,l,w),P(b,a,w),P(b,r,w),P(b,c,w),s(c,p),s(p,q),s(p,g),s(p,o),s(o,d),s(o,k),s(o,v),s(o,C),s(o,D),s(o,J),s(o,M),s(o,X),s(o,$),s(o,ne),s(o,F),s(p,u),s(p,E),s(E,se),P(b,W,w),j.m(b,w),P(b,I,w),L&&L.m(b,w),P(b,Z,w),R&&R.m(b,w),P(b,Q,w),P(b,H,w),y||(x=[G(q,"click",e[10]),G(q,"keydown",e[14]),G(d,"click",Le(e[10])),G(v,"click",Le(e[15])),G(D,"click",Le(e[16])),G(M,"click",Le(e[17])),G(F,"click",e[18]),G(E,"click",e[19])],y=!0)},p(b,w){w[0]&32&&te(d,"active",b[5]==="home"),w[0]&32&&te(v,"active",b[5]==="docs"),w[0]&32&&te(D,"active",b[5]==="benchmarks"),w[0]&32&&te(M,"active",b[5]==="community"),w[0]&8&&Y!==(Y=b[3]?"✕":"☰")&&de(se,Y),w[0]&16&&te(c,"scrolled",b[4]),ie===(ie=ae(b))&&j?j.p(b,w):(j.d(1),j=ie(b),j&&(j.c(),j.m(I.parentNode,I))),b[5]==="benchmarks"?L||(L=It(),L.c(),L.m(Z.parentNode,Z)):L&&(L.d(1),L=null),b[5]==="community"?R||(R=Dt(),R.c(),R.m(Q.parentNode,Q)):R&&(R.d(1),R=null)},i:fe,o:fe,d(b){b&&(S(t),S(l),S(a),S(r),S(c),S(W),S(I),S(Z),S(Q),S(H)),j.d(b),L&&L.d(b),R&&R.d(b),y=!1,me(x)}}}function At(e){return e?e.replace(/```(?:dart|bash|javascript|json)?\s*\n([\s\S]*?)\n```/g,(r,c)=>{const p=c.trim().replace(/'/g,"\\'");return`<div class="code-block-wrapper">
                    <div class="code-block-header">
                        <div class="window-controls">
                            <span class="control red"></span>
                            <span class="control yellow"></span>
                            <span class="control green"></span>
                        </div>
                        <span class="lang-label">${r.includes("bash")?"Terminal":"Source"}</span>
                        <button class="copy-btn" onclick="this.innerText='Copied!'; setTimeout(()=>this.innerText='Copy', 2000); navigator.clipboard.writeText('${p}')">Copy</button>
                    </div>
                    <div class="code-block"><pre><code>${c.trim()}</code></pre></div>
                  </div>`}).replace(/^### (.*$)/gm,(r,c)=>`<h3 class="doc-h3" id="${c.toLowerCase().replace(/\s+/g,"-")}">${c}</h3>`).replace(/^## (.*$)/gm,(r,c)=>`<h2 class="doc-h2" id="${c.toLowerCase().replace(/\s+/g,"-")}">${c}</h2>`).replace(/\*\*(.*?)\*\*/g,"<strong>$1</strong>").replace(/`([^`\n]+)`/g,'<code class="inline-code">$1</code>').replace(/^\s*- (.*)$/gm,"<li>$1</li>").split(`
`).map(r=>{const c=r.trim();return c?c.startsWith("<h")||c.startsWith("<div")||c.startsWith("<li")||c.startsWith("</")?r:`<p>${r}</p>`:""}).join(`
`):""}function ds(e,t,l){let a,r,c,p,q,g=Ve[0],o=Ve[0].sections[0],d=!1,k=!1,v="home";Ft(()=>{window.addEventListener("scroll",()=>{l(4,k=window.scrollY>20)});const y=()=>{const x=window.location.hash;x.startsWith("#/docs")?l(5,v="docs"):x==="#/benchmarks"?l(5,v="benchmarks"):x==="#/community"?l(5,v="community"):l(5,v="home")};window.addEventListener("hashchange",y),y()});function C(y,x){l(2,g=y),l(0,o=x),l(5,v="docs"),l(3,d=!1),window.scrollTo({top:0,behavior:"smooth"}),window.location.hash=`#/docs/${y.id}/${x.id}`}function D(){l(5,v="home"),window.location.hash="",window.scrollTo({top:0,behavior:"smooth"})}const J=[{title:"Pre-compiled Routing",desc:"Pre-built middleware chains during startup for extreme throughput.",icon:"🚀"},{title:"ORM Relationships",desc:'Declarative "belongsTo" and "hasMany" support for complex data models.',icon:"🗄️"},{title:"Universal Caching",desc:'Elegant "Cache" facade with built-in Memory and Redis drivers.',icon:"🚄"},{title:"Declarative Validation",desc:'Validate input using simple string rules like "required|email|min:8".',icon:"✅"},{title:"Native Sessions",desc:"Secure server-side cookie sessions with persistent storage support.",icon:"🛡️"},{title:"CLI Scaffolding",desc:"Rapidly generate models, migrations, and controllers with one command.",icon:"⚙️"}];let M="";const X=y=>y.key==="Enter"&&D(),$=()=>window.location.hash="#/docs",ne=()=>window.location.hash="#/benchmarks",F=()=>window.location.hash="#/community",u=()=>window.location.hash="#/docs",E=()=>l(3,d=!d),Y=()=>l(5,v="docs"),se=()=>l(5,v="docs");function W(){M=this.value,l(1,M)}const I=(y,x)=>C(y,x),Z=()=>C(c.cat,c),Q=()=>C(p.cat,p),H=y=>{const x=document.getElementById(y[1].toLowerCase().replace(/\s+/g,"-"));x&&x.scrollIntoView({behavior:"smooth",block:"start"})};return e.$$.update=()=>{e.$$.dirty[0]&8193&&l(12,r=a.findIndex(y=>y.id===o.id)),e.$$.dirty[0]&12288&&l(8,c=r>0?a[r-1]:null),e.$$.dirty[0]&12288&&l(7,p=r<a.length-1?a[r+1]:null),e.$$.dirty[0]&2&&l(6,q=Ve.map(y=>({...y,sections:y.sections.filter(x=>x.title.toLowerCase().includes(M.toLowerCase())||y.title.toLowerCase().includes(M.toLowerCase()))})).filter(y=>y.sections.length>0))},l(13,a=Ve.flatMap(y=>y.sections.map(x=>({...x,cat:y})))),[o,M,g,d,k,v,q,p,c,C,D,J,r,a,X,$,ne,F,u,E,Y,se,W,I,Z,Q,H]}class us extends ls{constructor(t){super(),ss(this,t,ds,cs,jt,{},null,[-1,-1])}}new us({target:document.getElementById("app")});
