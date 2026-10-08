/// wenku8 页面解析用 JS 片段。
///
/// 这些脚本在 WebView 中执行（已通过 Cloudflare 挑战的会话）。目标页面的 HTML
/// 由 `CfPageLoader` 通过同源 `fetch` 取回并用 `DOMParser` 解析后放入
/// `window.__doc`，因此各脚本统一从 `window.__doc` 读取文档；若为空则回退到
/// 当前 document。返回值均为 JSON 字符串，结构与 Rust 端 `client.rs` 保持一致。
class Wenku8Js {
  /// 取文档根（双模式，供两种抓取路径复用同一份解析脚本）：
  /// 1. `WebViewFetcher.fetchParsedEx`：作用域内有 `html`（已按 GBK 解码），解析之；
  /// 2. `CfPageLoader`：无 `html`，回退到 `window.__doc`（fetch 回来的目标页），
  ///    再回退到当前 `document`。
  static const String _docPrelude = r'''
var __root = (typeof html !== 'undefined' && html)
  ? new DOMParser().parseFromString(html, 'text/html')
  : ((window.__doc && window.__doc.querySelector) ? window.__doc : document);
''';

  /// 用户详情页（userdetail.php）：返回用户信息 JSON。
  ///
  /// 复刻 Rust `parse_user_detail`：遍历 `tr[align=left]`，取 `td.odd`（标题）
  /// 与 `td.even`（值）配对。
  static const String userDetail = r'''
(function() {
  var doc = new DOMParser().parseFromString(html, 'text/html');
  var out = {};
  function set(k, v) { out[k] = (v || '').trim(); }
  doc.querySelectorAll('tr[align="left"], tr[align=left]').forEach(function(tr) {
    var odd = tr.querySelector('td.odd');
    var even = tr.querySelector('td.even');
    if (!odd || !even) return;
    var title = (odd.textContent || '').trim();
    var value = (even.textContent || '').trim();
    if (title.indexOf('用户ID：') === 0) set('userId', value);
    else if (title.indexOf('用户名：') === 0) set('username', value);
    else if (title.indexOf('昵称：') === 0) set('nickname', value.replace('(留空则用户名做昵称)', ''));
    else if (title.indexOf('等级：') === 0) set('level', value);
    else if (title.indexOf('头衔：') === 0) set('title', value);
    else if (title.indexOf('性别：') === 0) set('sex', value);
    else if (title.indexOf('Email：') === 0) set('email', value);
    else if (title.indexOf('QQ：') === 0) set('qq', value);
    else if (title.indexOf('MSN：') === 0) set('msn', value);
    else if (title.indexOf('网站：') === 0) set('web', value);
    else if (title.indexOf('注册日期：') === 0) set('registerDate', value);
    else if (title.indexOf('贡献值：') === 0) set('contributePoint', value);
    else if (title.indexOf('经验值：') === 0) set('experienceValue', value);
    else if (title.indexOf('现有积分：') === 0) set('holdingPoints', value);
    else if (title.indexOf('最多好友数：') === 0) set('quantityOfFriends', value);
    else if (title.indexOf('信箱最多消息数：') === 0) set('quantityOfMail', value);
    else if (title.indexOf('书架最大收藏量：') === 0) set('quantityOfCollection', value);
    else if (title.indexOf('每天允许推荐次数：') === 0) set('quantityOfRecommendDaily', value);
    else if (title.indexOf('用户签名：') === 0) set('personalizedSignature', value);
    else if (title.indexOf('个人简介：') === 0) set('personalizedDescription', value);
  });
  return JSON.stringify(out);
})()
''';

  /// 章节正文提取（在 `fetchParsed` 中执行，`html` 为已按 GBK 解码的页面源码）。
  ///
  /// 复刻 Rust `parse` 的正文抽取：跳过 <ul> 水印，<br> 转换行，<img> 转
  /// `<!--image-->url<!--image-->` 占位。返回正文字符串。
  static const String chapterText = r'''
(function() {
  var doc = new DOMParser().parseFromString(html, 'text/html');
  var content = doc.querySelector('#content');
  if (!content) return '';
  function abs(src) {
    src = (src || '').trim();
    if (!src) return '';
    if (src.indexOf('http://') === 0 || src.indexOf('https://') === 0) return src;
    if (src.indexOf('//') === 0) return 'https:' + src;
    if (src.indexOf('/image/') === 0) return 'https://img.wenku8.com' + src;
    if (src.indexOf('image/') === 0) return 'https://img.wenku8.com/' + src;
    return src;
  }
  var buf = '';
  function walk(node) {
    var children = node.childNodes;
    for (var i = 0; i < children.length; i++) {
      var c = children[i];
      if (c.nodeType === 3) {
        buf += (c.textContent || '').replace(/\u00a0/g, ' ');
      } else if (c.nodeType === 1) {
        var name = c.tagName.toLowerCase();
        if (name === 'ul') continue;
        if (name === 'br') { buf += '\n'; continue; }
        if (name === 'img') {
          var u = abs(c.getAttribute('src'));
          if (u) buf += '\n<!--image-->' + u + '<!--image-->\n';
          continue;
        }
        walk(c);
      }
    }
  }
  walk(content);
  return buf.trim();
})()
''';

  /// 首页（index.php）：返回 `[{title, list:[{title,img,detailUrl,aid}]}]`。
  static const String indexBlocks = r'''
(function() {
''' + _docPrelude + r'''
  function aidOf(href) {
    var m = href.match(/\/book\/([^\/]+)\.htm/);
    if (m) return m[1];
    return href.split('/').pop().replace('.htm', '');
  }
  var result = [];
  var centersBlocks = __root.querySelectorAll('#centers .block');
  for (var i = 1; i < centersBlocks.length && result.length < 3; i++) {
    var block = centersBlocks[i];
    var titleEl = block.querySelector('.blocktitle');
    var title = titleEl ? (titleEl.textContent || '').trim() : '';
    if (!title) continue;
    var list = [];
    block.querySelectorAll('.blockcontent > div > div').forEach(function(d) {
      var as = d.querySelectorAll('a');
      var img = d.querySelector('img');
      if (!img || as.length === 0) return;
      var href = as[0].getAttribute('href') || '';
      if (!href) return;
      var t = as.length > 1 ? (as[1].textContent || '').trim() : '';
      list.push({ title: t, img: img.getAttribute('src') || '', detailUrl: href, aid: aidOf(href) });
    });
    if (list.length) result.push({ title: title, list: list });
  }
  var mains = __root.querySelectorAll('div.main');
  for (var k = 5; k < Math.min(7, mains.length); k++) {
    mains[k].querySelectorAll('.block').forEach(function(block) {
      var titleEl = block.querySelector('.blocktitle');
      var title = titleEl ? (titleEl.textContent || '').trim() : '';
      if (!title) return;
      if (title === '文库Telegram群组') return;
      if (title.indexOf('轻小说文库公告') === 0) return;
      var list = [];
      block.querySelectorAll('div > a > img').forEach(function(img) {
        var a = img.parentElement;
        if (!a) return;
        var href = a.getAttribute('href') || '';
        if (!href) return;
        var t = a.getAttribute('title') || a.textContent || '';
        list.push({ title: (t || '').trim(), img: img.getAttribute('src') || '', detailUrl: href, aid: aidOf(href) });
      });
      if (list.length) result.push({ title: title, list: list });
    });
  }
  return JSON.stringify(result);
})()
''';

  /// 列表页（tags.php / toplist.php / articlelist.php）：
  /// 返回 `{currentPage, maxPage, records:[{title,img,detailUrl,aid}], diag}`。
  static const String listPage = r'''
(function() {
''' + _docPrelude + r'''
  function aidOf(href) {
    var m = href.match(/\/book\/([^\/]+)\.htm/);
    if (m) return m[1];
    return href.split('/').pop().replace('.htm', '');
  }
  var seen = {};
  var records = [];
  __root.querySelectorAll('a[href*="/book/"]').forEach(function(a) {
    var href = a.getAttribute('href') || '';
    if (!href || seen[href]) return;
    if (href.indexOf('bookcase') >= 0 || href.indexOf('login') >= 0) return;
    var title = (a.getAttribute('title') || a.textContent || '').trim();
    var img = a.querySelector('img');
    if (!img) {
      var prev = a.previousElementSibling;
      if (prev && prev.querySelector) img = prev.querySelector('img');
    }
    if (!img) {
      var parent = a.parentElement;
      if (parent && parent.querySelector) img = parent.querySelector('img');
    }
    var imgSrc = img ? (img.getAttribute('src') || '') : '';
    if (!title && !imgSrc) return;
    seen[href] = true;
    records.push({ title: title, img: imgSrc, detailUrl: href, aid: aidOf(href) });
  });
  var currentPage = 1, maxPage = 1;
  var stat = __root.querySelector('em#pagestats');
  if (stat) {
    var parts = stat.textContent.split('/');
    currentPage = parseInt(parts[0], 10) || 1;
    maxPage = parseInt(parts[1], 10) || currentPage;
  }
  return JSON.stringify({
    currentPage: currentPage,
    maxPage: maxPage,
    records: records,
    diag: {
      grid: __root.querySelectorAll('table.grid').length,
      bookLinks: __root.querySelectorAll('a[href*="/book/"]').length,
      imgs: __root.querySelectorAll('img').length
    }
  });
})()
''';

  /// 分类页（tags.php）：返回 `[{title, tags:[{name, href}]}]`。
  ///
  /// `href` 是站点自身生成的、已按 GBK 百分号编码的链接，便于后续直接复用。
  static const String tagGroups = r'''
(function() {
''' + _docPrelude + r'''
  var groups = [];
  var name = '';
  var tags = [];
  function pushGroup() {
    if (name || tags.length) groups.push({ title: name, tags: tags.slice() });
  }
  var uls = __root.querySelectorAll('ul.ultops');
  if (uls.length === 0) uls = __root.querySelectorAll('ul');
  uls.forEach(function(ul) {
    ul.querySelectorAll('li').forEach(function(li) {
      var html = (li.innerHTML || '').trim();
      var links = li.querySelectorAll('a[href*="tags.php"]');
      if (links.length === 0) links = li.querySelectorAll('a');
      var isHeader = html.indexOf('Tags：') >= 0 && links.length === 0;
      if (isHeader) {
        pushGroup();
        name = html.replace('Tags：', '').replace('系', '').replace('属性', '').replace('类', '').trim();
        tags = [];
      } else {
        links.forEach(function(a) {
          var t = (a.textContent || '').trim();
          if (!t) return;
          tags.push({ name: t, href: a.href || '' });
        });
      }
    });
  });
  pushGroup();
  return JSON.stringify(groups);
})()
''';

  /// 小说详情页（articleinfo.php）：
  /// 返回 `{title,author,status,finUpdate,imgUrl,introduce,tags,heat,trending,isAnimated}`。
  static const String novelInfo = r'''
(function() {
''' + _docPrelude + r'''
  function txt(el) { return el ? (el.textContent || '').trim() : ''; }
  function skip(s, n) { return s.length > n ? s.substring(n).trim() : ''; }
  var out = {
    title: '', author: '', status: '', finUpdate: '',
    imgUrl: '', introduce: '', tags: [], heat: '', trending: '', isAnimated: false
  };
  var content = __root.querySelector('#content');
  if (!content) return JSON.stringify(out);
  var table = content.querySelector('table');
  if (table) {
    var spans = table.querySelectorAll('span');
    if (spans.length) {
      var b = spans[0].querySelector('b');
      out.title = txt(b || spans[0]);
    }
    var trs = table.querySelectorAll('tr');
    if (trs.length > 2) {
      var tds = trs[2].querySelectorAll('td');
      if (tds.length > 1) out.author = skip(txt(tds[1]), 5);
      if (tds.length > 2) out.status = skip(txt(tds[2]), 5);
      if (tds.length > 3) out.finUpdate = skip(txt(tds[3]), 5);
    }
  }
  var img = content.querySelector('img');
  if (img) out.imgUrl = img.getAttribute('src') || '';
  var tables = content.querySelectorAll('table');
  if (tables.length > 2) {
    var t2tds = tables[2].querySelectorAll('td');
    if (t2tds.length > 1) {
      var t2spans = t2tds[1].querySelectorAll('span');
      if (t2spans.length > 5) {
        out.introduce = t2spans[5].innerHTML || '';
      } else if (t2spans.length > 3) {
        out.introduce = skip(txt(t2spans[3]), 5);
      }
      if (t2spans.length > 0) {
        var tagText = txt(t2spans[0]);
        out.tags = skip(tagText, 7).split(' ').filter(function(x) { return x.length > 0; });
      }
      // 动画化标记：站点在标签区额外放一个文本含「动画」的 span。
      // 不能仅凭 span 数量判断（几乎每本书都有多个 span，会全部误判）。
      for (var si = 0; si < t2spans.length; si++) {
        if (txt(t2spans[si]).indexOf('动画') >= 0) { out.isAnimated = true; break; }
      }
    }
  }
  return JSON.stringify(out);
})()
''';

  /// 详情页解析（供 `WebViewFetcher.fetchParsedEx` 使用，输入 `html`）。
  static const String novelInfoFromHtml = r'''
(function() {
  var __doc = new DOMParser().parseFromString(html, 'text/html');
  var __root = __doc;
  function txt(el) { return el ? (el.textContent || '').trim() : ''; }
  function skip(s, n) { return s.length > n ? s.substring(n).trim() : ''; }
  var out = {
    title: '', author: '', status: '', finUpdate: '',
    imgUrl: '', introduce: '', tags: [], heat: '', trending: '', isAnimated: false
  };
  var content = __root.querySelector('#content');
  if (!content) return JSON.stringify(out);
  var table = content.querySelector('table');
  if (table) {
    var spans = table.querySelectorAll('span');
    if (spans.length) {
      var b = spans[0].querySelector('b');
      out.title = txt(b || spans[0]);
    }
    var trs = table.querySelectorAll('tr');
    if (trs.length > 2) {
      var tds = trs[2].querySelectorAll('td');
      if (tds.length > 1) out.author = skip(txt(tds[1]), 5);
      if (tds.length > 2) out.status = skip(txt(tds[2]), 5);
      if (tds.length > 3) out.finUpdate = skip(txt(tds[3]), 5);
    }
  }
  var img = content.querySelector('img');
  if (img) out.imgUrl = img.getAttribute('src') || '';
  var tables = content.querySelectorAll('table');
  if (tables.length > 2) {
    var t2tds = tables[2].querySelectorAll('td');
    if (t2tds.length > 1) {
      var t2spans = t2tds[1].querySelectorAll('span');
      if (t2spans.length > 5) {
        out.introduce = t2spans[5].innerHTML || '';
      } else if (t2spans.length > 3) {
        out.introduce = skip(txt(t2spans[3]), 5);
      }
      if (t2spans.length > 0) {
        var tagText = txt(t2spans[0]);
        out.tags = skip(tagText, 7).split(' ').filter(function(x) { return x.length > 0; });
      }
      // 动画化标记：站点在标签区额外放一个文本含「动画」的 span。
      for (var si2 = 0; si2 < t2spans.length; si2++) {
        if (txt(t2spans[si2]).indexOf('动画') >= 0) { out.isAnimated = true; break; }
      }
    }
  }
  return JSON.stringify(out);
})()
''';

  /// 章节目录解析（供 `WebViewFetcher.fetchParsedEx` 使用，输入 `html`）。
  static const String readerVolumesFromHtml = r'''
(function() {
  var __doc = new DOMParser().parseFromString(html, 'text/html');
  var __root = __doc;
  function param(href, key) {
    var m = href.match(new RegExp('[?&]' + key + '=([^&]+)'));
    return m ? decodeURIComponent(m[1]) : '';
  }
  var volumes = [];
  var table = __root.querySelector('table.css');
  if (!table) return JSON.stringify(volumes);
  var vid = '', vtitle = '', chapters = [];
  table.querySelectorAll('tr').forEach(function(tr) {
    var vcss = tr.querySelector('td.vcss');
    if (vcss) {
      if (vid !== '') volumes.push({ id: vid, title: vtitle, chapters: chapters });
      vid = vcss.getAttribute('vid') || '';
      vtitle = (vcss.textContent || '').trim();
      chapters = [];
    } else {
      tr.querySelectorAll('td.ccss > a').forEach(function(a) {
        var href = a.getAttribute('href') || '';
        chapters.push({
          title: (a.textContent || '').trim(),
          url: href,
          cid: param(href, 'cid'),
          aid: param(href, 'aid')
        });
      });
    }
  });
  if (vid !== '') volumes.push({ id: vid, title: vtitle, chapters: chapters });
  return JSON.stringify(volumes);
})()
''';

  /// 章节目录页（reader.php）：返回 `[{id,title,chapters:[{title,url,cid,aid}]}]`。
  static const String readerVolumes = r'''
(function() {
''' + _docPrelude + r'''
  function param(href, key) {
    var m = href.match(new RegExp('[?&]' + key + '=([^&]+)'));
    return m ? decodeURIComponent(m[1]) : '';
  }
  var volumes = [];
  var table = __root.querySelector('table.css');
  if (!table) return JSON.stringify(volumes);
  var vid = '', vtitle = '', chapters = [];
  table.querySelectorAll('tr').forEach(function(tr) {
    var vcss = tr.querySelector('td.vcss');
    if (vcss) {
      if (vid !== '') volumes.push({ id: vid, title: vtitle, chapters: chapters });
      vid = vcss.getAttribute('vid') || '';
      vtitle = (vcss.textContent || '').trim();
      chapters = [];
    } else {
      tr.querySelectorAll('td.ccss > a').forEach(function(a) {
        var href = a.getAttribute('href') || '';
        chapters.push({
          title: (a.textContent || '').trim(),
          url: href,
          cid: param(href, 'cid'),
          aid: param(href, 'aid')
        });
      });
    }
  });
  if (vid !== '') volumes.push({ id: vid, title: vtitle, chapters: chapters });
  return JSON.stringify(volumes);
})()
''';
}
