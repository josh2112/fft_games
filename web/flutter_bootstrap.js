{{flutter_js}}
{{flutter_build_config}}

const statusDiv = document.getElementById('status');
statusDiv.textContent = "Loading entry point...";
_flutter.loader.load({
    onEntrypointLoaded: async function (engineInitializer) {
        statusDiv.textContent = "Initializing engine...";
        const appRunner = await engineInitializer.initializeEngine();

        statusDiv.textContent = "Running app...";
        await appRunner.runApp();
    }
});