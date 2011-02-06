var args = window.location.href.slice(window.location.href.indexOf('?') + 1);
var urlvars = getUrlVars(args);

var tx = urlvars['tx'];
var ty = urlvars['ty'];
var layer = urlvars['layer'];
var itype = urlvars['itype'];
var filename = ty+'-'+tx+layer;

function getUrlVars(args)
{
	var vars = [], hash;
	var hashes = args.split('&');
	for(var i = 0; i < hashes.length; i++){
		hash = hashes[i].split('=');
		vars.push(hash[0]);
		vars[hash[0]] = hash[1];
	}
  return vars;
}

