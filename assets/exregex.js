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

  CodeMirror.defineExRegexMode = function (name, ruleset) {
    CodeMirror.defineMode(name, function (config) {
      return CodeMirror.exRegexMode(config, ruleset);
    });
  };

  CodeMirror.exRegexMode = function (config, ruleset) {
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
		  
		  
          matches.push([begin, end, i]);
          stack.push([spos, begin, i]);
          stack.push([end, epos, i]);
		  //if match happens, we should not match another rule in this position
		  break; 
        }
      }

      matches.sort(function (a, b) {
        var a0 = a[0];
		var a2 = a[2];
        var b0 = b[0];
		var b2 = b[2];
		//when start location of matches differs, the match with lower (close to zero) start location comes first
		//when matches have same start location, the match with high priority match rule (lower in rule number) comes first
        return a0 < b0 ? -1 : (a0 > b0 ? 1 : (a2 < b2? -1:(a2 > b2? 1 : 0 ) ) );
      });
	  console.log(matches);
      return matches;
    }


    return {
      token: function (stream, state) {
        if (!state.hasOwnProperty("matches") || stream.pos == 0) {
          state["matches"] = regmatch(stream.string, state.rules);
        }

        for (var i = 0; i < state.matches.length; i++) {
          var match = state.matches[i];
          var start = match[0];
          var end = match[1];
          var rulenum = match[2];

          if (stream.pos == start) {
            stream.pos = end;
            return ruleset[rulenum]["token"];
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

