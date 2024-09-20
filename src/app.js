import { Elm } from './Main.elm'

var storedData = localStorage.getItem('myapp-model');
var flags = storedData ? JSON.parse(storedData) : null;

const app = Elm.Main.init({
  node: document.getElementById('app'),
  flags: flags
})

app.ports.saveData.subscribe(function(state) {
    localStorage.setItem('myapp-model', JSON.stringify(state));
});