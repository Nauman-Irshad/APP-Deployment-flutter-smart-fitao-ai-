/**
 * Browser NLP engine (FAQ TF-IDF + 3D product matching) — works without /api/chat (APK + Vercel).
 */
(function (global) {
  var DEFAULT_SUGGESTIONS = [
    'How do I try on a kurta virtually?',
    'What is SmartFitao?',
    'Show me black kurta',
    'What are the two order types?',
    'What is the return policy?',
    'How long does delivery take?',
  ];

  var PRODUCT_STOP = new Set([
    'show', 'me', 'see', 'view', 'want', 'give', 'get', 'i', 'we', 'the', 'a', 'an',
    'my', 'can', 'you', 'please', 'need', 'have', 'has', 'is', 'are', 'in', 'for',
    'to', 'and', 'or', 'it', 'this', 'that', 'product', 'products', '3d', 'style', 'styles',
    'only', 'just', 'really',
  ]);
  var COLOR_PHRASES = ['sky blue', 'black', 'brown', 'white'];
  var PRODUCT_TYPES = new Set(['kurta', 'kameez', 'shalwar', 'shalwaar', 'kurtas']);
  var PRODUCT_COLORS = new Set(['black', 'brown', 'white', 'sky', 'blue']);

  var faqCache = null;
  var productsCache = null;
  var loadPromise = null;

  function dataBase() {
    var script = document.currentScript;
    if (script && script.src) {
      return script.src.replace(/\/[^/]*$/, '/');
    }
    var path = window.location.pathname || '/';
    if (path.endsWith('/')) return path;
    return path.replace(/\/[^/]*$/, '/') || '/';
  }

  function clean(text) {
    return String(text || '')
      .toLowerCase()
      .replace(/[^\w\s.,?!'-]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
  }

  function tokens(text) {
    var t = clean(text);
    if (!t) return [];
    return t.split(/\s+/).filter(Boolean);
  }

  function tfVector(tokList) {
    var v = Object.create(null);
    for (var i = 0; i < tokList.length; i++) {
      var t = tokList[i];
      v[t] = (v[t] || 0) + 1;
    }
    return v;
  }

  function cosine(a, b) {
    var dot = 0;
    var na = 0;
    var nb = 0;
    for (var k in a) {
      na += a[k] * a[k];
      if (b[k]) dot += a[k] * b[k];
    }
    for (var k2 in b) nb += b[k2] * b[k2];
    if (!na || !nb) return 0;
    return dot / (Math.sqrt(na) * Math.sqrt(nb));
  }

  function loadFaq() {
    return faqCache;
  }

  function loadProducts() {
    return productsCache || [];
  }

  function preload() {
    if (loadPromise) return loadPromise;
    var base = dataBase();
    loadPromise = Promise.all([
      fetch(base + 'data/faq.json').then(function (r) {
        if (!r.ok) throw new Error('faq.json');
        return r.json();
      }),
      fetch(base + 'data/products.json').then(function (r) {
        if (!r.ok) throw new Error('products.json');
        return r.json();
      }),
    ])
      .then(function (pair) {
        faqCache = pair[0];
        productsCache = pair[1];
        return true;
      })
      .catch(function () {
        faqCache = faqCache || [];
        productsCache = productsCache || [];
        return false;
      });
    return loadPromise;
  }

  function prefetchProductGlbs(products) {
    if (!products || !products.length) return;
    var seen = {};
    products.forEach(function (p) {
      var url = String(p.model_url || '').trim();
      if (!url || seen[url]) return;
      seen[url] = true;
      var link = document.createElement('link');
      link.rel = 'preload';
      link.as = 'fetch';
      link.href = url;
      link.crossOrigin = 'anonymous';
      document.head.appendChild(link);
      fetch(url, { mode: 'cors', headers: { Range: 'bytes=0-65535' } }).catch(function () {});
    });
  }

  function faqAnswer(question) {
    var faq = loadFaq();
    if (!faq || !faq.length) return null;
    var qVec = tfVector(tokens(question));
    var best = null;
    var bestScore = 0;
    for (var i = 0; i < faq.length; i++) {
      var row = faq[i];
      var score = cosine(qVec, tfVector(tokens(row.question)));
      if (score > bestScore) {
        bestScore = score;
        best = row.answer;
      }
    }
    if (bestScore >= 0.28 && best) return { answer: best, source: 'faq', score: bestScore };
    return null;
  }

  function normalizeMatch(text) {
    return clean(text).replace(/shalwaar/g, 'shalwar');
  }

  function productKeywords(query) {
    var q = normalizeMatch(query);
    var out = [];
    for (var i = 0; i < COLOR_PHRASES.length; i++) {
      var phrase = COLOR_PHRASES[i];
      if (q.indexOf(phrase) !== -1 && out.indexOf(phrase) === -1) out.push(phrase);
    }
    var words = q.split(/\s+/);
    for (var j = 0; j < words.length; j++) {
      var w = words[j];
      if (!w || PRODUCT_STOP.has(w)) continue;
      var wn = normalizeMatch(w);
      if ((PRODUCT_COLORS.has(wn) || PRODUCT_TYPES.has(wn) || wn === 'shalwar') && out.indexOf(wn) === -1) {
        out.push(wn);
      }
    }
    return out;
  }

  function isProductRequest(question) {
    var q = clean(question);
    var triggers = [
      'show', 'see', 'view', '3d', 'product', 'kurta', 'kameez', 'shalwar',
      'black', 'white', 'brown', 'blue', 'sky', 'display', 'browse', 'catalog',
    ];
    for (var i = 0; i < triggers.length; i++) {
      if (q.indexOf(triggers[i]) !== -1) return true;
    }
    return false;
  }

  function shouldFastPathProducts(question) {
    if (!isProductRequest(question)) return false;
    var q = clean(question);
    if (/\b(how|why|explain|works?|what is|tell me about)\b/.test(q)) return false;
    var visual = ['show', 'see', 'view', 'display', 'browse', 'find', 'look', 'give me', 'want'];
    var kws = productKeywords(question);
    var hasTerms =
      kws.length > 0 || ['kurta', 'shalwar', 'kameez', 'product'].some(function (t) {
        return q.indexOf(t) !== -1;
      });
    for (var i = 0; i < visual.length; i++) {
      if (q.indexOf(visual[i]) !== -1 && hasTerms) return true;
    }
    var words = q.split(/\s+/).filter(function (w) {
      return !PRODUCT_STOP.has(w);
    });
    return hasTerms && words.length <= 5;
  }

  function searchProducts(query) {
    var products = loadProducts();
    if (!query || !String(query).trim()) return products;
    var q = normalizeMatch(query);
    var candidates = products;
    var wantsShalwar = q.indexOf('shalwar') !== -1 || (q.indexOf('kameez') !== -1 && q.indexOf('kurta') === -1);
    var wantsKurta = q.indexOf('kurta') !== -1;
    if (wantsShalwar && !wantsKurta) {
      candidates = products.filter(function (p) {
        return p.category === 'shalwar kameez';
      });
    } else if (wantsKurta && !wantsShalwar) {
      candidates = products.filter(function (p) {
        return p.category === 'kurta';
      });
    }
    var kws = productKeywords(query);
    if (!kws.length) return candidates;
    var typeKws = kws.filter(function (k) {
      return PRODUCT_TYPES.has(k) || k === 'shalwar';
    });
    var colorKws = kws.filter(function (k) {
      return PRODUCT_COLORS.has(k) || COLOR_PHRASES.indexOf(k) !== -1;
    });
    return candidates.filter(function (p) {
      var blob = normalizeMatch(p.match_key || p.name);
      for (var i = 0; i < typeKws.length; i++) {
        if (blob.indexOf(typeKws[i]) === -1) return false;
      }
      for (var j = 0; j < colorKws.length; j++) {
        if (blob.indexOf(colorKws[j]) === -1) return false;
      }
      return true;
    });
  }

  function buildProductPayload(question) {
    var products = searchProducts(question);
    var all = loadProducts();
    var payload = { sources: [], answer_source: 'product', products: [] };
    if (products.length) {
      payload.products = products.map(function (p) {
        return {
          name: p.name,
          model_url: p.model_url,
          category: p.category || '',
        };
      });
      var names = products.map(function (p) {
        return p.name;
      });
      if (names.length === 1) {
        payload.answer = 'Here is ' + names[0] + ' in 3D. You can rotate and zoom below.';
      } else if (names.length === all.length) {
        payload.answer =
          'Here are all ' + names.length + ' Smart Fitao 3D products (kurta and shalwar kameez). View them below.';
      } else {
        payload.answer =
          'Here are ' + names.length + ' 3D products for your request: ' + names.join(', ') + '. View them below.';
      }
    } else {
      payload.answer = all.length
        ? 'Sorry, that color or style is not available. We have: ' +
          all
            .map(function (p) {
              return p.name;
            })
            .join(', ') +
          '.'
        : 'No 3D products available at the moment.';
    }
    return payload;
  }

  function handleChat(question) {
    var q = String(question || '').trim();
    if (!q) return Promise.resolve({ error: 'question is required', status: 400 });

    return preload().then(function () {
      if (shouldFastPathProducts(q)) {
        return { status: 200, body: buildProductPayload(q) };
      }

      var faq = faqAnswer(q);
      if (faq) {
        var payload = { answer: faq.answer, answer_source: faq.source, sources: [] };
        if (shouldFastPathProducts(q)) {
          var prod = buildProductPayload(q);
          if (prod.products && prod.products.length) {
            return { status: 200, body: Object.assign({}, prod, { answer_source: 'product' }) };
          }
        }
        return { status: 200, body: payload };
      }

      return {
        status: 200,
        body: {
          answer: 'No information about this. You can ask these:',
          show_suggestions: true,
          suggestions: DEFAULT_SUGGESTIONS,
          sources: [],
          answer_source: 'local',
        },
      };
    });
  }

  global.SmartFitaoChatEngine = {
    preload: preload,
    handleChat: handleChat,
    DEFAULT_SUGGESTIONS: DEFAULT_SUGGESTIONS,
  };
})(typeof window !== 'undefined' ? window : globalThis);
