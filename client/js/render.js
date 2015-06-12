var scene, viewer;
var rotationX = 0, rotationY = 0;
var divX = document.getElementById('rotation_x');
var divY = document.getElementById('rotation_y');
var divDistance = document.getElementById('distance');

function rotate(x, y, z){
    scene.camera.rotateX(x).rotateZ(y).rotateY(z);
    viewer.update();
}

function getAngles(){
    var r = new XMLHttpRequest();
    r.open('get','http://192.168.100.39:4567', true);
    r.send();
    r.onreadystatechange = function(){
        if (r.readyState != 4 || r.status != 200) return;
        var angles = r.responseText.split(' ');

        divX.textContent = angles[0];
        divY.textContent = angles[1];
        divDistance.textContent = angles[2];

        x_deg = Math.PI * (parseFloat(angles[0]) - rotationX)/ 180;
        y_deg = Math.PI * (parseFloat(angles[1]) - rotationY)/ 180;

        rotate(x_deg, y_deg, 0);
        rotationX = parseFloat(angles[0]);
        rotationY = parseFloat(angles[1]);
    }
}

window.onload = function() {
    var paper = Raphael('canvas', 1000, 800);
    var mat = new Raphael3d.Material('#363', '#030');
    var cube = Raphael3d.Surface.Box(0, 0, 0, 5, 4, 0.15, paper, {});
    scene = new Raphael3d.Scene(paper);
    scene.setMaterial(mat).addSurfaces(cube);
    scene.projection = Raphael3d.Matrix4x4.PerspectiveMatrixZ(900);
    viewer = paper.Viewer(45, 45, 998, 798, {opacity: 0});
    viewer.setScene(scene).fit();
    rotate(-1.5,0.2, 0);

    var timer = setInterval(getAngles, 100);
    document.getElementById('canvas').onclick = function(){
        clearInterval(timer);
    }
}
