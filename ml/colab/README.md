# H10 Model A — Google Colab Training Guide

Per project specification and lead engineer guidelines, local training is avoided to prevent unnecessary computational bottlenecks. Instead, training is performed either in Google Colab (with free cloud GPU/TPU/CPU) or using `train_colab.py`.

## Quick Start (Google Colab)
1. Open [Google Colab](https://colab.research.google.com/).
2. Select **File -> Upload notebook** and upload `ml/colab/H10_Exercise_Recognition_Colab.ipynb`.
3. Follow the notebook cells:
   - Upload your recorded dataset JSON (e.g. `synthetic_dataset.json` or recorded trial dataset).
   - Run the training pipeline (`python ml/colab/train_colab.py`).
   - The script performs GroupKFold cross-validation by participant, trains Random Forest baseline and Keras MLP, quantizes to TensorFlow Lite (`h10_exercise_recognizer.tflite`), and calculates the SHA-256 hash.
   - Run the final cell to download `h10_exercise_recognizer.tflite` and `manifest.json`.
4. Copy the downloaded `h10_exercise_recognizer.tflite` and `manifest.json` into `mobile/assets/models/`.

## Offline / Headless CLI Run
You can also run the training script directly:
```bash
python ml/colab/train_colab.py --dataset ml/data/synthetic_dataset.json --output ml/models
```
