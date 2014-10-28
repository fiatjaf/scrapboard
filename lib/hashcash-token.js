(function(e, a) { for(var i in a) e[i] = a[i]; }(exports, /******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId])
/******/ 			return installedModules[moduleId].exports;
/******/
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			exports: {},
/******/ 			id: moduleId,
/******/ 			loaded: false
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.loaded = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(0);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ function(module, exports, __webpack_require__) {

	module.exports = {
	  generate: __webpack_require__(1),
	  validate: __webpack_require__(2)
	}

/***/ },
/* 1 */
/***/ function(module, exports, __webpack_require__) {

	var hex = __webpack_require__(3)
	var validate = __webpack_require__(2)
	var hash = __webpack_require__(4)
	var sha256 = require('./sha256').sha256

	var NONCE_UPPER_BOUND = 10000000000000;


	module.exports = function(opts) {
	  var difficulty = opts.difficulty || 1000000;
	  var nonce = opts.nonce || Math.floor(Math.random() * NONCE_UPPER_BOUND);
	  var data = opts.data || sha256(nonce);

	  var token = {
	    difficulty: difficulty,
	    data: data,
	    nonce: nonce
	  }

	  var target = hex.convertDifficultyToTarget(difficulty)
	  do {
	    token.nonce++;
	    token.hash = hash(token)
	  } while (parseInt("0x" + token.hash) > target);

	  token.rarity = hex.getHashRarity(token.hash);

	  return token;
	}

/***/ },
/* 2 */
/***/ function(module, exports, __webpack_require__) {

	var hash = __webpack_require__(4)
	var hex = __webpack_require__(3)

	module.exports = function(token, constraints) {
	  if (!token || typeof token.difficulty !== "number" || typeof token.nonce !==
	    "number" || typeof token.data !== "string" || typeof token.rarity !==
	    "number" || typeof token.hash !== "string") {
	    return false;
	  }

	  if (typeof constraints === "object") {
	    if (typeof constraints.difficulty === "number" && constraints.difficulty >
	      token.difficulty) {
	      return false;
	    }
	    if (constraints.data && constraints.data !== token.data) {
	      return false;
	    }
	    if (typeof constraints.rarity === "number" && constraints.rarity > token.rarity) {
	      return false;
	    }
	  }

	  if (token.hash !== hash(token)) {
	    return false;
	  };

	  if (token.rarity !== hex.getHashRarity(token.hash)) {
	    return false;
	  }

	  var target = hex.convertDifficultyToTarget(token.difficulty);
	  if (parseInt("0x" + token.hash) < target) {
	    return true;
	  } else {
	    return false;
	  }

	}

/***/ },
/* 3 */
/***/ function(module, exports, __webpack_require__) {

	var sha256 = require('./sha256').sha256

	var MAX_HASH =
	  0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

	exports.convertDifficultyToTarget = function(difficulty) {
	  var target = MAX_HASH / difficulty;
	  return target;
	}

	exports.getHashRarity = function(hash) {
	  return 1 / (parseInt("0x" + hash) / MAX_HASH);
	}

/***/ },
/* 4 */
/***/ function(module, exports, __webpack_require__) {

	var sha256 = require('./sha256').sha256
	var DELIMITER = "|"

	module.exports = function(token) {
	  return sha256([token.difficulty, token.data, token.nonce].join(DELIMITER))
	}

/***/ }
/******/ ])))
