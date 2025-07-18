window.playMetronomeSound = function(url, volume) {
  try {
    const audio = new Audio(url);
    audio.volume = volume !== undefined ? volume : 1.0;
    audio.currentTime = 0;
    audio.play();
  } catch (e) {
    console.error('Audio play error:', e);
  }
}; 