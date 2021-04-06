// CodeMirror, copyright (c) by Marijn Haverbeke and others
// Distributed under an MIT license: https://codemirror.net/LICENSE

// mode written by d8888 (smallt@gmail.com)

(function (mod) {
  if (typeof exports == "object" && typeof module == "object") // CommonJS
    mod(require("codemirror/lib/codemirror"));
  else if (typeof define == "function" && define.amd) // AMD
    define(["codemirror/lib/codemirror"], mod);
  else // Plain browser env
    mod(CodeMirror);
})(function (CodeMirror) {
  "use strict";



  //initialize dictionary
  english_word_list = english_word_list.concat(custom_word_list)
  
  var slicedDict={};

  //minimal length of English word to be checked, any word less than this length will not be spell-checked and is always "valid"
  var min_check_word_length = 3;

  //cache for checked words
  var checked_words = {};
  
  function loadDict() {
	//https://codepen.io/_kkeisuke/pen/BJGpqG

	var n = english_word_list.length;
	for (var i = 0; i < n; i++) {
	  var key = english_word_list[i].substring(0, 3);
	  if (!(key in slicedDict)) {
		slicedDict[key] = {};
	  }
	  slicedDict[key][english_word_list[i]]=true;
    }
  }
  loadDict();

  CodeMirror.defineExRegexMode = function (name, ruleset) {
    CodeMirror.defineMode(name, function (config) {
      return CodeMirror.exRegexMode(config, ruleset);
    });
  };

  CodeMirror.exRegexMode = function (config, ruleset) {
    function checkword(word) {
      if(word.length < min_check_word_length)
      {
        return true;
      }

      word = String(word).toLowerCase();
	  
	  var key = word.substring(0, 3);
	  
      
      if(word in checked_words) {
        return checked_words[word];
      }
	
      var rst = key in slicedDict && word in slicedDict[key];
      checked_words[word] = rst;
      return rst;
    }

    function checkspell(input) {
      const regexp = /([a-zA-Z]+)/g;
      var array = [...input.matchAll(regexp)];

      var rst = [];
      for (var i = 0; i < array.length; i++) {

        if (!checkword(array[i][0])) {
          //concat starting pos and ending pos of every word with wrong spelling
          rst = rst.concat([[array[i].index, array[i].index + array[i][0].length]]);
        }
      }
      return rst;
    }

    function patchmatch(matches, errors) {
      var newmatch = [];
      var matchtriggered = {};
      for (var j = 0; j < matches.length; j++) {
        matchtriggered[j] = false;
      }
      for (var i = 0; i < errors.length; i++) {
        var triggered = false;
        var s1 = errors[i][0];
        var e1 = errors[i][1];
        for (var j = 0; j < matches.length; j++) {

          var s2 = matches[j][0];
          var e2 = matches[j][1];
          var token = matches[j][2];

          var s3 = Math.max(s1, s2);
          var e3 = Math.min(e1, e2);
          if (s3 < e3) {
            //has "intersection" of 'spelling error' and 'current match'
            triggered = true;
            matchtriggered[j] = true;
            //match 左端有部份沒有 spell error
            if (s3 > s2) {
              var frag = [s2, s3, token];
              newmatch = newmatch.concat([frag]);
            }

            var frag = [s3, e3, token + " spellerror"];
            newmatch = newmatch.concat([frag]);

            //error 右端有部份在 match 外面
            if (e1 > e3) {
              var frag = [e3, e1, "spellerror"];
              newmatch = newmatch.concat([frag]);
            }
          }
        }
        if (!triggered) {
          var frag = [s1, e1, "spellerror"];
          newmatch = newmatch.concat([frag]);
        }
      }
      for (var key in matchtriggered) {
        if (!matchtriggered[key]) {
          newmatch = newmatch.concat([matches[key]]);
        }
      }
      newmatch = sortmatch(newmatch);

      return newmatch;
    }

    function sortmatch(matches) {
      matches.sort(function (a, b) {
        var a0 = a[0];
        var a2 = a[2];
        var b0 = b[0];
        var b2 = b[2];
        //when start location of matches differs, the match with lower (close to zero) start location comes first
        //when matches have same start location, the match with high priority match rule (lower in rule number) comes first
        return a0 < b0 ? -1 : (a0 > b0 ? 1 : (a2 < b2 ? -1 : (a2 > b2 ? 1 : 0)));
      });
      return matches;
    }


    function regmatch(input, rules) {
      var matches = [];
      var stack = [];
      stack.push([0, input.length, 0]);

      while (stack.length > 0) {

        var temp = stack.pop();
        var spos = temp[0];
        var epos = temp[1];
        var startrule = temp[2];

        if (epos <= spos) {
          continue;
        }

        for (var i = startrule; i < rules.length; i++) {
          var match = input.slice(spos, epos).match(rules[i]["regex"]);
          if (!match) {
            continue;
          }
          var begin = match.index + spos;
          var end = match.index + match[0].length + spos;


          matches.push([begin, end, rules[i]["token"]]);
          stack.push([spos, begin, i]);
          stack.push([end, epos, i]);
          //if match happens, we should not match another rule in this position
          break;
        }
      }
      matches = sortmatch(matches);

      return matches;
    }


    return {
      token: function (stream, state) {
        if (!state.hasOwnProperty("matches") || stream.pos == 0) {
          state["matches"] = regmatch(stream.string, state.rules);
          state["checkspell"] = checkspell(stream.string);
          state["matches"] = patchmatch(state["matches"], state["checkspell"]);
        }




        for (var i = 0; i < state.matches.length; i++) {
          var match = state.matches[i];
          var start = match[0];
          var end = match[1];
          var token = match[2];


          if (stream.pos == start) {
            stream.pos = end;
            return token;
          }
        }
        stream.next();

        return null;
      },


      startState: function () {
        return {
          "rules": ruleset
        };
      }
    };
  };


});

