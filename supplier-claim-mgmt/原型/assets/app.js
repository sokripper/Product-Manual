// 共享侧栏/顶栏注入。页面在 <body data-active="claim" data-crumb="理赔管理 / xxx"> 上声明。
(function(){
  var NAV=[
    {k:'claim', ic:'📋', t:'理赔管理'},
    {k:'settle',ic:'🧾', t:'结算管理'},
    {k:'pay',   ic:'💳', t:'支付管理'},
    {k:'config',ic:'⚙️', t:'系统配置'}
  ];
  function el(html){var d=document.createElement('div');d.innerHTML=html.trim();return d.firstChild;}
  document.addEventListener('DOMContentLoaded',function(){
    var active=document.body.dataset.active||'';
    var crumb=document.body.dataset.crumb||'';
    var sb=document.getElementById('sidebar');
    if(sb){
      sb.innerHTML='<div class="brand"><b>服务商索赔管理</b><span>Warranty Claim Console</span></div>'+
        '<nav class="nav">'+NAV.map(function(n){
          return '<a class="'+(n.k===active?'active':'')+'" href="#"><span class="ic">'+n.ic+'</span>'+n.t+'</a>';
        }).join('')+'</nav>'+
        '<div class="nav"><a href="../index.html"><span class="ic">🗂️</span>原型总览</a></div>'+
        '<div class="foot">李索赔专员 · 华东区</div>';
    }
    var tb=document.getElementById('topbar');
    if(tb){
      var parts=crumb.split('/').map(function(s,i,a){return i===a.length-1?'<b>'+s.trim()+'</b>':s.trim();}).join(' <span>/</span> ');
      tb.innerHTML='<div class="crumb">'+parts+'</div>'+
        '<div class="right"><span>🔔</span><span>❔</span><span class="avatar">李</span></div>';
    }
  });
})();
