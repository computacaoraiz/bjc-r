/*
 * Common functions for any llab page
 *
 * CANNOT RELY ON JQUERY OR ANY OTHER LLAB LIBRARY
 */


// retrieve llab or create an empty version.
llab = llab || {};
llab.loaded = llab.loaded || {};
llab.DEVELOPER_CLASSES = '.todo, .comment, .commentBig, .ap-standard, .csta-standard'


////// TRANSLATIONS -- Shared Across All Files.
llab.TRANSLATIONS = {
    'ifTime': {
      en: 'If There Is Time…',
      es: 'Si hay tiempo…',
    },
    'takeItFurther': {
      en: 'Take It Further…',
      es: 'Llevándolo más allá',
    },
    'takeItTeased': {
      en: 'Take It Further…',
      es: 'Llevándolo más allá',
    },
    'backText': {
      en: 'previous page',
      es: 'previous page',
    },
    'nextText': {
      en: 'next page',
      es: 'next page',
    },
    'selfCheckTitle': {
      en: 'Self-Check Question',
      es: 'Autoevaluación',
    },
    'Try Again': {
      es: 'Intentarlo de nuevo',
    },
    'Check Answer': {
      es: 'Comprobar respuesta',
    },
    'successMessage': {
      en: 'You have successfully completed this question!',
      es: '¡Has completado la pregunta correctamente!',
    },
    'attemptMessage': {
      en: 'This is your %{ordinal} attempt.',
      es: 'Este es tu intento n.º %{number}.',
    },
    'Go to Table of Contents': {
      es: 'Ir a la tabla de contenido'
    }
};


/////////////////
llab.snapRunURLBase = "https://snap.berkeley.edu/snap/snap.html#open:";
llab.snapRunURLBaseVersion = "https://snap.berkeley.edu/versions/VERSION/snap.html#open:";

// It is expected that you host llab content in an environment where CORS is allowed.
llab.getSnapRunURL = function(targeturl, options) {
    if (!targeturl) { return ''; }

    if (targeturl.indexOf('http') == 0 || targeturl.indexOf('//') == 0) {
        // pointing to some non-local resource... do nothing!!
        return targeturl;
    }

    // internal resource!
    let snapURL = llab.snapRunURLBase;
    if (options && options.version) {
        snapURL = llab.snapRunURLBaseVersion.replace('VERSION', options.version);
    }
    if (location.protocol == 'http:') {
        snapURL = snapURL.replace('https://snap', 'http://extensions.snap');
    }

    let origin = location.origin;
    // Resolve relative URLs to the full path.
    // TODO: Consider adapting: new URL("../g", "http://a/b/c/d;p?q").href
    if (targeturl.indexOf("..") != -1 || targeturl.indexOf(llab.rootURL) == -1) {
        let path = location.pathname;
        path = path.split("?")[0];
        path = path.substring(0, path.lastIndexOf("/") + 1);
        origin += path;
    }

    return `${snapURL}${origin}${targeturl}`;
};

llab.pageLang = () => {
    if (llab.CURRENT_PAGE_LANG) {
        return llab.CURRENT_PAGE_LANG;
    }

    let htmlLang = $("html").attr('lang');
    if (!htmlLang) {
        htmlLang = llab.determineAltLang();
        $("html").attr('lang', htmlLang);
      }
    llab.CURRENT_PAGE_LANG = htmlLang || 'en';
    return llab.CURRENT_PAGE_LANG;
}

// Use the filename of the HTML file or course file, or topic file to determine page language.
llab.determineAltLang = () => {
    let altLang = location.href.match(/\.(\w\w)\.(html|topic)/);
    if (altLang) {
        return altLang[1];
    }
    return 'en';
}

// loosely mirror the Rails API, `lang` is optional.
llab.translate = (key, replacements) => {
    if (!llab.TRANSLATIONS) { return key; }

    if (!replacements) { replacements = {}; }

    let dictionary = llab.TRANSLATIONS[key],
        lang = llab.pageLang();

    if (!dictionary) { return key; }
    let result = dictionary[lang];
    if (result !== '' && !result) {
      result = dictionary['en'] || key;
    }

    Object.keys(replacements).forEach(key => {
      result = result.replaceAll(`%{${key}}`, replacements[key]);
    })
    return result;
};
llab.t = llab.translate;

llab.toggleDevComments = () => {
    $(llab.DEVELOPER_CLASSES).toggle();
};

llab.showAllDevComments = () => {
    $(llab.DEVELOPER_CLASSES).show();
}

llab.setUpDevComments = function() {
    if (llab.isLocalEnvironment()) {
        if ($('.js-commentBtn').length < 1) {
            let addToggle = $('<button class="imageRight btn btn-default js-commentBtn">')
                .click(llab.toggleDevComments)
                .text('Toggle developer todos/comments (red boxes)');
            $(FULL).prepend(addToggle);
        }
        $(window).load(llab.showAllDevComments);
    }
}

/** Returns the value of the URL parameter associated with NAME. */
llab.getQueryParameter = function(paramName) {
    var params = llab.getURLParameters();
    if (params.hasOwnProperty(paramName)) {
        return params[paramName];
    } else {
        return '';
    }
};

/** Strips comments off the line in a topic file. */
llab.stripComments = function(line) {
    var index = line.indexOf("//");
    // the second condition makes this ignore urls (http://...)
    if (index !== -1 && line[index - 1] !== ":") {
        line = line.slice(0, index);
    }
    return line;
};

/* Google Analytics Tracking
 * To make use of this code, the two ga() functions need to be called
 * on each page that is loaded, which means this file must be loaded.
 */
llab.GA = function() {
    let ga_url = `https://www.googletagmanager.com/gtag/js?id=${llab.GACode}`;
    document.head.appendChild(getTag('script', ga_url, 'text/javascript'));
};

// GA Function Calls -- these do the real work!:
if (llab.GACode) {
    llab.GA();
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());

    gtag('config', llab.GACode);
}

/** Truncate a STR to an output of N chars.
 *  N does NOT include any HTML characters in the string.
 */
llab.truncate = function(str, n) {
    // Ensure string is 'proper' HTML by putting it in a div, then extracting.
    var clean = document.createElement('div');
        clean.innerHTML = str;
        clean = clean.textContent || clean.innerText || '';

    // TODO: Be smarter about stripping from HTML content
    // This, doesn't factor HTML into the removed length
    // Perhaps match postion of nth character to the original string?
    // &#8230; is a unicode ellipses
    if (clean.length > n) {
        return clean.slice(0, n - 1) + '&#8230;';
    }

    return str; // return the HTML content if possible.
};


// TODO: Replace this with new URLSearchParams(window.location.search)
/*!
    query-string
    Parse and stringify URL query strings
    https://github.com/sindresorhus/query-string
    by Sindre Sorhus
    MIT License
*/
// Modiefied for LLAB. Inlined to reduce requests
var queryString = {};

queryString.parse = function (str) {
    if (typeof str !== 'string') {
        return {};
    }

    str = str.trim().replace(/^(\?|#)/, '');

    if (!str) {
        return {};
    }

    return str.trim().split('&').reduce(function (ret, param) {
        var parts = param.replace(/\+/g, ' ').split('=');
        var key = parts[0];
        var val = parts[1];

        key = decodeURIComponent(key);
        // missing `=` should be `null`:
        // http://w3.org/TR/2012/WD-url-20120524/#collect-url-parameters
        val = val === undefined ? null : decodeURIComponent(val);

        if (!ret.hasOwnProperty(key)) {
            ret[key] = val;
        } else if (Array.isArray(ret[key])) {
            ret[key].push(val);
        } else {
            ret[key] = [ret[key], val];
        }

        return ret;
    }, {});
};

queryString.stringify = function (obj) {
    return obj ? Object.keys(obj).map(function (key) {
        var val = obj[key];

        if (Array.isArray(val)) {
            return val.map(function (val2) {
                if (!val2) { // Mod: Don't have =null values in URL params
                    return encodeURIComponent(key);
                }
                return encodeURIComponent(key) + '=' + encodeURIComponent(val2);
            }).join('&');
        }

        if (!val) { // Mod: Don't have =null values in URL params
            return encodeURIComponent(key);
        }

        return encodeURIComponent(key) + '=' + encodeURIComponent(val);
    }).join('&') : '';
};
/*! End Query String */
llab.QS = queryString;


// Return a new object with the combined properties of A and B.
// Desgined for merging query strings
// B will clobber A if the fields are the same.
llab.merge = function(objA, objB) {
    var result = {}, prop;
    for (prop in objA) {
        if (objA.hasOwnProperty(prop)) {
            result[prop] = objA[prop];
        }
    }
    for (prop in objB) {
        if (objB.hasOwnProperty(prop)) {
            result[prop] = objB[prop];
        }
    }
    return result;
};

llab.getURLParameters = function() {
    return llab.QS.parse(location.search);
};

llab.getAttributesForElement = function(elm) {
    var map = elm.attributes,
        ignore = ['class', 'id', 'style'],
        attrs = {},
        item,
        i = 0,
        len = map.length;

    for (; i < len; i += 1) {
        item = map.item(i);
        if (ignore.indexOf(item.name) === -1) {
            attrs[item.name] = item.value;
        }
    }
    return attrs;
};


// These are STRINGS that are query selectors for selecting page elements
// We want to store them in a single place because it's easier to update
llab.selectors = {};
// These are code fragments which are reusable components.
llab.fragments = {};
// These are common strings that need not be build and should be reused!
llab.strings = {};
llab.strings.goMain = 'Go to Table of Contents';
llab.fragments.bootstrapSep = '<li class="divider list_item" role="presentation"></li>';
llab.fragments.bootstrapCaret = '<span class="caret"></span>';
// TODO: Translate this
llab.fragments.hamburger = '<span class="sr-only">Toggle navigation</span><span class="icon-bar"></span><span class="icon-bar"></span><span class="icon-bar"></span>';
// LLAB selectors for common page elements
llab.selectors.FULL = '.full';
llab.selectors.NAVSELECT = '.llab-nav';
llab.selectors.PROGRESS = '.full-bottom-bar';

//// cookie stuff
// someday my framework will come, but for now, stolen blithely from http://www.quirksmode.org/js/cookies.html
llab.createCookie = function(name,value,days) {
    if (days) {
        var date = new Date();
        date.setTime(date.getTime()+(days*24*60*60*1000));
        var expires = "; expires="+date.toGMTString();
    }
    else var expires = "";
    document.cookie = name+"="+value+expires+"; path=/";
}

llab.readCookie = function(name) {
    var nameEQ = name + "=";
    var ca = document.cookie.split(';');
    for(var i=0;i < ca.length;i++) {
        var c = ca[i];
        while (c.charAt(0)==' ') c = c.substring(1,c.length);
        if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
    }
    return null;
}

llab.eraseCookie = function(name) {
    createCookie(name,"",-1);
}

llab.spanTag = function(content, className) {
    return '<span class="' + className + '">' + content + '</span>'
}

// TODO: Replace with native JS some/every.
llab.any = function(A) {
    return A.reduce(function(x, y) {return x || y });
}

llab.all = function(A) {
    return A.reduce(function(x, y) {return x && y });
}

llab.which = function(A) {
    for (i = 0; i < A.length; i++) {
        if (A[i]) {
            return i;
        }
    }
    return -1;
}


///////////////////// END

llab.loaded['library'] = true;
