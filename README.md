# MATLAB Generative Music Composer

Break Through Tech AI Studio Project 2024: Music Composition with MATLAB

Using MATLAB's **Deep Learning Toolbox** and **Audio Toolbox**, we analyzed and implemented LSTMs and Deep Learning Techniques to generate a model capable of composing and playing back music. The project combines the power of LSTM networks with MIDI data to create music that captures the essence of polyphonic compositions.

## Table of Contents
- [Project Overview](#project-overview)
- [Methodology](#methodology)
- [Results and Key Findings](#results-and-key-findings)
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)
- [Credits and Acknowledgments](#credits-and-acknowledgments)

---

## Project Overview

### Objectives
The goal of this project was to build a generative music model capable of:
1. Composing melodies from a single MIDI file or multiple polyphonic inputs.
2. Generating MIDI output files for playback and evaluation.
3. Exploring deep learning approaches to model musical structures.

### Significance
Generative music has wide applications in creative industries, from autonomous music composition to personalized soundtracks for games and apps. This project tackles the challenge of representing musical structure through a computational model, contributing to the field of AI-driven music synthesis.

---

## Methodology

### Data Preparation
- **Input Data:** MIDI files were used as the primary data source. We used the [GiantMIDI-Piano dataset](https://github.com/bytedance/GiantMIDI-Piano?tab=readme-ov-file)
- **Preprocessing:** MIDI tracks were parsed to extract delta times, note numbers, and velocities, followed by normalization for deep learning compatibility.
- **Feature Engineering:** Notes and velocities were grouped and formatted into sequences for polyphonic representation.

### Model Architecture
An LSTM-based architecture was designed to model musical sequences:
- **Input Layer:** Handles grouped notes and velocities as features.
- **LSTM Layer:** Captures sequential dependencies in the music.
- **Fully Connected Layer:** Maps LSTM outputs to the appropriate feature space.
- **Regression Layer:** Outputs predicted notes and velocities for the next time step.

### Training
The model was trained using the **Adam optimizer** with a sequence-to-sequence prediction strategy, generating notes based on previous time steps.

---

## Results and Key Findings  

### Generated Output  
- Successfully generated polyphonic MIDI compositions from trained models.  
- Demonstrated the ability to capture complex musical patterns using LSTMs.  

### Key Metrics  
- Performance was evaluated subjectively through the musical quality of generated outputs.  
- Training curves (e.g., loss reduction) indicated model convergence.  

### Visualizations  
![Training Loss over Epochs](placeholder-for-training-curve.png)  
*Training Loss over Epochs*  

Generated music was saved as MIDI files for playback evaluation.  

### Potential Next Steps  
- Extend the model to handle longer temporal dependencies for intricate compositions.
- Experiment with other architectures, such as Transformer models, for improved sequence modeling.
- Deploy the model as an interactive music-generation tool.

---

## Installation

1. Clone the repository:  
   ```bash  
   git clone https://github.com/your-repository.git  
   cd your-repository  

2. Ensure MATLAB is installed with:  
- Deep Learning Toolbox  
- Audio Toolbox  
3. Add the repository folder to MATLAB's path
4. Download desired MIDI dataset, and make sure folder of midis are added to MATLAB path.

## Usage  
Single MIDI File Generation:  
Use onemidiLSTM.m to generate melodies from a single MIDI file  
  
Polyphonic MIDI Composition:  
Use polymidisLSTM.m for generating compositions from multiple MIDI files
  
MIDI Output:
Generated files are saved in the repository directory. Playback is supported via any MIDI player.

## Contributing
Contributions are welcome! Please follow these steps:
1. Fork the repository.  
2. Create a feature branch:
   ```bash
    git checkout -b feature-name
   ```
4. Commit your changes:
   ```bash
    git commit -m "Description of changes"
   ```
6. Submit a pull request for review

## License
This project is licensed under the Apache License, Version 2.0. Feel free to use, modify, and distribute the code, provided proper attribution is maintained.

## Credits and Acknowledgments
Contributors
- Project Team: Marie Elster, Erynn Gutierrez, Isabella Juhaeri, Lindsey McGovern, Chenlu Wang
- AI Challenge Advisor (Mathworks): Maiteyi Chitale
- AI Studio TA (BTTAI Studio): George Abu Doud  

Tools and Libraries
- MATLAB Deep Learning Toolbox
- MATLAB Audio Toolbox
- [matlab-midi by kts](https://github.com/kts/matlab-midi/tree/master?tab=readme-ov-file)

