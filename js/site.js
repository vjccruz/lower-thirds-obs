function preview() {
	var id = document.getElementsByName('idtype')[0].value;
	var line1 = document.getElementById('line1').value;
	var color1 = document.getElementById('color1').value;
	var line2 = document.getElementById('line2').value;
	var color2 = document.getElementById('color2').value;

	if (color1.indexOf('#') === 0) {
		color1 = color1.substr(1);
	}
	if (color2.indexOf('#') === 0) {
		color2 = color2.substr(1);
	}
	
	console.log('Id: ' + id);
	console.log('Line1: ' + line1 + ' Color: ' + color1);
	console.log('Line2: ' + line2 + ' Color: ' + color2);
	
	var url = '/lower?id=' + id + '&line1=' + encodeURI(line1) + '&color1=' + color1 + '&line2=' + encodeURI(line2) + '&color2=' + color2;
	
	document.getElementsByTagName('iframe')[0].src = url;
	document.getElementById('url').innerHTML = 'https://obs.infor-r.com' + url;
	document.getElementById('hiddenURL').value = 'https://obs.infor-r.com' + url;
}

function changeColorPicker(element, color) {
	document.getElementById(color).value = element.value;
}

function clickToCopy(element) {
	var copyText = document.getElementById('hiddenURL');
	copyText.select();
	copyText.setSelectionRange(0, 99999);
	document.execCommand("copy");

	var tooltip = document.getElementById("urlTooltip");
	tooltip.innerHTML = "URL copied";

	setTimeout(function() {
		var tooltip = document.getElementById("urlTooltip");
		tooltip.innerHTML = "click to copy";
	}, 2000);
}