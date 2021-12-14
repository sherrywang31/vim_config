require([
    'base/js/namespace',
    'base/js/events'
    ],
    function(Jupyter, events) {
        events.on("notebook_loaded.Notebook",
            function () {
                Jupyter.notebook.set_autosave_interval(120000); //in milliseconds
            }
        );
    }
);
