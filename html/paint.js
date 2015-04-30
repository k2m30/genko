function paint(name){
    var svgobject = document.getElementById(name); // Находим тег <object>
    if ('contentDocument' in svgobject) {              // У нас действительно там что-то есть?
        var velocity = 2000; // mm/sec
        var delay = 0;
        var paths = document.getElementById(name).contentDocument.querySelectorAll('path');
        var transition = null;
        for (var i = 0; i < paths.length; i++) {
            l = paths[i].getTotalLength();
            paths[i].style.transition = paths[i].style.WebkitTransition = 'none';
            paths[i].style.strokeDasharray = l + ' ' + l;
            paths[i].style.strokeDashoffset = l;
            paths[i].style.markerStart = 'none';
            paths[i].style.markerEnd = 'none';
            time = l / velocity;
            transition = 'stroke-dashoffset ' + time + 's ease-in-out ' + delay + 's';
            delay += time;
            paths[i].getBoundingClientRect();
            paths[i].style.transition = paths[i].style.WebkitTransition = transition;
            paths[i].style.strokeDashoffset = '0';
        }
    }

};
