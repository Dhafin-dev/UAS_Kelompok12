import warnings
import os
warnings.filterwarnings('ignore')
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.model_selection import train_test_split
from imblearn.over_sampling import BorderlineSMOTE
from sklearn.metrics import (classification_report, accuracy_score, precision_score,
                              recall_score, f1_score, confusion_matrix)

# Import Keras untuk Deep Learning
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Conv1D, Flatten, Dropout, BatchNormalization
from tensorflow.keras.utils import to_categorical
from tensorflow.keras.callbacks import EarlyStopping

# Set random seed global untuk reproducibility penuh
np.random.seed(42)
tf.random.set_seed(42)

# ==========================================
# 1. INPUT
# ==========================================
print("1. Memuat dataset...")
df = pd.read_csv('ObesityDataSet_raw_and_data_sinthetic.csv')

# ==========================================
# 2. PREPROCESSING
# ==========================================
print("2. Melakukan Preprocessing...")

# 2a. Cek missing values
print("   -> Cek missing values per kolom:")
print(df.isnull().sum())

# 2b. Cek dan hapus data duplikat (jika ada)
jumlah_duplikat = df.duplicated().sum()
print(f"   -> Jumlah baris duplikat ditemukan: {jumlah_duplikat}")
if jumlah_duplikat > 0:
    df = df.drop_duplicates().reset_index(drop=True)
    print("   -> Duplikat telah dihapus.")

# 2c. Deteksi outlier pada kolom numerik menggunakan metode IQR
print("   -> Deteksi outlier (metode IQR) pada kolom numerik:")
num_cols_check = df.select_dtypes(include=['float64', 'int64']).columns
for col in num_cols_check:
    Q1 = df[col].quantile(0.25)
    Q3 = df[col].quantile(0.75)
    IQR = Q3 - Q1
    batas_bawah = Q1 - 1.5 * IQR
    batas_atas = Q3 + 1.5 * IQR
    outlier_count = df[(df[col] < batas_bawah) | (df[col] > batas_atas)].shape[0]
    print(f"      Kolom '{col}': {outlier_count} outlier terdeteksi")
# Catatan: outlier tidak dihapus (dipertahankan) karena dataset obesitas ini merupakan
# gabungan data survei asli & data sintetis, sehingga variasi ekstrem tetap valid secara klinis.

# Memisahkan fitur dan target (gunakan .copy() agar tidak terjadi SettingWithCopyWarning)
X = df.drop(columns=['NObeyesdad']).copy()
y = df['NObeyesdad']

# Encode fitur kategorikal (Label Encoding)
label_encoders = {}
cat_cols = X.select_dtypes(include=['object']).columns

for col in cat_cols:
    le = LabelEncoder()
    X[col] = le.fit_transform(X[col])
    label_encoders[col] = le

# Encode Target
le_target = LabelEncoder()
y_encoded = le_target.fit_transform(y)
num_classes = len(le_target.classes_)

# ==========================================
# 3. TRANSFORMATION (Scaling)
# ==========================================
print("3. Melakukan Transformation (Scaling)...")
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# ==========================================
# 4. DATA SPLITTING (Training : Validation : Testing = 80 : 10 : 10)
# ==========================================
print("4. Melakukan Data Splitting (80% Train : 10% Validation : 10% Test)...")

# Split pertama: pisahkan Test set (10%) dari keseluruhan data
X_temp, X_test, y_temp, y_test = train_test_split(
    X_scaled, y_encoded, test_size=0.10, random_state=42, stratify=y_encoded
)

# Split kedua: dari sisa 90% data, pisahkan Validation set (10% dari total awal
# => proporsi 1/9 dari X_temp) sehingga rasio akhir menjadi 80:10:10
X_train, X_val, y_train, y_val = train_test_split(
    X_temp, y_temp, test_size=(1/9), random_state=42, stratify=y_temp
)

print(f"   -> Jumlah data Training   : {X_train.shape[0]}")
print(f"   -> Jumlah data Validation : {X_val.shape[0]}")
print(f"   -> Jumlah data Testing    : {X_test.shape[0]}")

# Tampilkan distribusi kelas SEBELUM SMOTE
print("\n   -> Distribusi kelas SEBELUM BorderlineSMOTE:")
unique_before, counts_before = np.unique(y_train, return_counts=True)
for cls_idx, cnt in zip(unique_before, counts_before):
    print(f"      Kelas '{le_target.classes_[cls_idx]}': {cnt} sampel")

# Balancing dengan BorderlineSMOTE (HANYA pada data training, tidak boleh menyentuh
# data validation maupun testing agar evaluasi tetap merepresentasikan data asli)
smote = BorderlineSMOTE(random_state=42)
X_resampled, y_resampled = smote.fit_resample(X_train, y_train)

# Tampilkan distribusi kelas SESUDAH SMOTE
print("   -> Distribusi kelas SESUDAH BorderlineSMOTE:")
unique_after, counts_after = np.unique(y_resampled, return_counts=True)
for cls_idx, cnt in zip(unique_after, counts_after):
    print(f"      Kelas '{le_target.classes_[cls_idx]}': {cnt} sampel")

# Konversi target ke format Categorical (One-Hot Encoding) untuk Keras
y_resampled_cat = to_categorical(y_resampled, num_classes=num_classes)
y_val_cat = to_categorical(y_val, num_classes=num_classes)
y_test_cat = to_categorical(y_test, num_classes=num_classes)

# Persiapan input 3D untuk CNN 1D
X_resampled_cnn = X_resampled.reshape((X_resampled.shape[0], X_resampled.shape[1], 1))
X_val_cnn = X_val.reshape((X_val.shape[0], X_val.shape[1], 1))
X_test_cnn = X_test.reshape((X_test.shape[0], X_test.shape[1], 1))

# ==========================================
# 5. KLASIFIKASI: METODE DEEP LEARNING 1 & 2
# ==========================================
print("\n5. Membangun dan melatih model Deep Learning...")

# Callback EarlyStopping: menghentikan training jika val_loss tidak membaik
# selama 10 epoch berturut-turut, dan mengembalikan bobot terbaik
early_stopping = EarlyStopping(
    monitor='val_loss', patience=10, restore_best_weights=True, verbose=0
)

# --- METODE 1: Multi-Layer Perceptron (MLP) ---
# Arsitektur diperdalam: 3 hidden layers (64 -> 32 -> 16) dengan BatchNorm & Dropout
# untuk meningkatkan kapasitas model pada 7 kelas klasifikasi
model_mlp = Sequential([
    Dense(64, activation='relu', input_shape=(X_resampled.shape[1],)),
    BatchNormalization(),
    Dropout(0.3),
    Dense(32, activation='relu'),
    BatchNormalization(),
    Dropout(0.2),
    Dense(16, activation='relu'),
    BatchNormalization(),
    Dropout(0.2),
    Dense(num_classes, activation='softmax')
])
model_mlp.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])

print("   -> Training Metode 1: MLP...")
history_mlp = model_mlp.fit(
    X_resampled, y_resampled_cat,
    epochs=100, batch_size=32,
    validation_data=(X_val, y_val_cat),   # <-- pakai Validation set hasil split eksplisit
    callbacks=[early_stopping],
    verbose=0
)
print(f"      MLP selesai pada epoch ke-{len(history_mlp.history['loss'])} (max 100, EarlyStopping aktif)")

# --- METODE 2: Convolutional Neural Network 1D (CNN 1D) ---
model_cnn = Sequential([
    Conv1D(filters=32, kernel_size=2, activation='relu', input_shape=(X_resampled.shape[1], 1)),
    BatchNormalization(),
    Flatten(),
    Dense(16, activation='relu'),
    Dropout(0.2),
    Dense(num_classes, activation='softmax')
])
model_cnn.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])

print("   -> Training Metode 2: CNN 1D...")
history_cnn = model_cnn.fit(
    X_resampled_cnn, y_resampled_cat,
    epochs=100, batch_size=32,
    validation_data=(X_val_cnn, y_val_cat),  # <-- pakai Validation set hasil split eksplisit
    callbacks=[early_stopping],
    verbose=0
)
print(f"      CNN 1D selesai pada epoch ke-{len(history_cnn.history['loss'])} (max 100, EarlyStopping aktif)")

# ==========================================
# 6. EVALUASI & KOMPARASI (menggunakan Data Testing)
# ==========================================
print("\n6. Mengevaluasi dan Membandingkan Model...")

# Prediksi MLP
y_pred_mlp_prob = model_mlp.predict(X_test, verbose=0)
y_pred_mlp = np.argmax(y_pred_mlp_prob, axis=1)

# Prediksi CNN 1D
y_pred_cnn_prob = model_cnn.predict(X_test_cnn, verbose=0)
y_pred_cnn = np.argmax(y_pred_cnn_prob, axis=1)

# Hitung Metrik MLP
acc_mlp = accuracy_score(y_test, y_pred_mlp)
prec_mlp = precision_score(y_test, y_pred_mlp, average='weighted')
rec_mlp = recall_score(y_test, y_pred_mlp, average='weighted')
f1_mlp = f1_score(y_test, y_pred_mlp, average='weighted')

# Hitung Metrik CNN 1D
acc_cnn = accuracy_score(y_test, y_pred_cnn)
prec_cnn = precision_score(y_test, y_pred_cnn, average='weighted')
rec_cnn = recall_score(y_test, y_pred_cnn, average='weighted')
f1_cnn = f1_score(y_test, y_pred_cnn, average='weighted')

print("\n=======================================================")
print("             HASIL KOMPARASI (KLASIFIKASI)             ")
print("=======================================================")
print(f"{'Metrik':<15} | {'Metode 1 (MLP)':<15} | {'Metode 2 (CNN 1D)':<15}")
print("-" * 55)
print(f"{'Akurasi':<15} | {acc_mlp:.4f}          | {acc_cnn:.4f}")
print(f"{'Presisi':<15} | {prec_mlp:.4f}          | {prec_cnn:.4f}")
print(f"{'Recall':<15} | {rec_mlp:.4f}          | {rec_cnn:.4f}")
print(f"{'F1-Score':<15} | {f1_mlp:.4f}          | {f1_cnn:.4f}")
print("=======================================================\n")

# Classification Report lengkap (untuk lampiran laporan)
print("--- Classification Report: MLP ---")
print(classification_report(y_test, y_pred_mlp, target_names=le_target.classes_))

print("--- Classification Report: CNN 1D ---")
print(classification_report(y_test, y_pred_cnn, target_names=le_target.classes_))

# Menentukan Model Terbaik
if f1_mlp >= f1_cnn:
    best_model = model_mlp
    best_model_name = "MLP"
    best_history = history_mlp
    best_y_pred = y_pred_mlp
else:
    best_model = model_cnn
    best_model_name = "CNN 1D"
    best_history = history_cnn
    best_y_pred = y_pred_cnn

print(f"Model terbaik berdasarkan F1-Score adalah: {best_model_name}")

# ==========================================
# VISUALISASI UNTUK LAPORAN UAS (KEDUA MODEL)
# ==========================================
print("\nMenyiapkan grafik untuk Laporan UAS...")

# 1. Grafik Akurasi dan Loss untuk KEDUA model (2x2 subplot)
fig, axes = plt.subplots(2, 2, figsize=(16, 12))

# MLP - Accuracy
axes[0, 0].plot(history_mlp.history['accuracy'], label='Train Accuracy', color='blue')
axes[0, 0].plot(history_mlp.history['val_accuracy'], label='Validation Accuracy', color='orange')
axes[0, 0].set_title('MLP - Model Accuracy', fontweight='bold')
axes[0, 0].set_xlabel('Epoch')
axes[0, 0].set_ylabel('Accuracy')
axes[0, 0].legend()
axes[0, 0].grid(True, linestyle='--', alpha=0.7)

# MLP - Loss
axes[0, 1].plot(history_mlp.history['loss'], label='Train Loss', color='red')
axes[0, 1].plot(history_mlp.history['val_loss'], label='Validation Loss', color='green')
axes[0, 1].set_title('MLP - Model Loss', fontweight='bold')
axes[0, 1].set_xlabel('Epoch')
axes[0, 1].set_ylabel('Loss')
axes[0, 1].legend()
axes[0, 1].grid(True, linestyle='--', alpha=0.7)

# CNN 1D - Accuracy
axes[1, 0].plot(history_cnn.history['accuracy'], label='Train Accuracy', color='blue')
axes[1, 0].plot(history_cnn.history['val_accuracy'], label='Validation Accuracy', color='orange')
axes[1, 0].set_title('CNN 1D - Model Accuracy', fontweight='bold')
axes[1, 0].set_xlabel('Epoch')
axes[1, 0].set_ylabel('Accuracy')
axes[1, 0].legend()
axes[1, 0].grid(True, linestyle='--', alpha=0.7)

# CNN 1D - Loss
axes[1, 1].plot(history_cnn.history['loss'], label='Train Loss', color='red')
axes[1, 1].plot(history_cnn.history['val_loss'], label='Validation Loss', color='green')
axes[1, 1].set_title('CNN 1D - Model Loss', fontweight='bold')
axes[1, 1].set_xlabel('Epoch')
axes[1, 1].set_ylabel('Loss')
axes[1, 1].legend()
axes[1, 1].grid(True, linestyle='--', alpha=0.7)

plt.suptitle('Perbandingan Training: MLP vs CNN 1D', fontsize=14, fontweight='bold')
plt.tight_layout()
plt.savefig('Grafik_Training_Komparasi.png', dpi=300)
plt.close()

# 2. Confusion Matrix untuk KEDUA model (side by side)
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(20, 8))

cm_mlp = confusion_matrix(y_test, y_pred_mlp)
sns.heatmap(cm_mlp, annot=True, fmt='d', cmap='Blues',
            xticklabels=le_target.classes_, yticklabels=le_target.classes_, ax=ax1)
ax1.set_title('Confusion Matrix - MLP', fontweight='bold')
ax1.set_ylabel('Actual')
ax1.set_xlabel('Prediction')
ax1.set_xticklabels(ax1.get_xticklabels(), rotation=45, ha='right')

cm_cnn = confusion_matrix(y_test, y_pred_cnn)
sns.heatmap(cm_cnn, annot=True, fmt='d', cmap='Oranges',
            xticklabels=le_target.classes_, yticklabels=le_target.classes_, ax=ax2)
ax2.set_title('Confusion Matrix - CNN 1D', fontweight='bold')
ax2.set_ylabel('Actual')
ax2.set_xlabel('Prediction')
ax2.set_xticklabels(ax2.get_xticklabels(), rotation=45, ha='right')

plt.suptitle('Perbandingan Confusion Matrix: MLP vs CNN 1D', fontsize=14, fontweight='bold')
plt.tight_layout()
plt.savefig('Confusion_Matrix_Komparasi.png', dpi=300)
plt.close()

print("Grafik training dan confusion matrix kedua model telah disimpan sebagai file PNG.")

# ==========================================
# 7. OUTPUT: SIMPAN MODEL UNTUK GUI
# ==========================================
filename = f"model_obesitas_{best_model_name.replace(' ', '').lower()}.keras"
best_model.save(filename)
print(f"\n7. Output: Model terbaik telah disimpan sebagai '{filename}' untuk diintegrasikan ke GUI Mobile (Flutter/Kivy).")