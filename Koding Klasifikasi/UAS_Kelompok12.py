import warnings
import os

warnings.filterwarnings('ignore')
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

os.environ['TF_USE_LEGACY_KERAS'] = '1'

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.model_selection import train_test_split
from imblearn.over_sampling import BorderlineSMOTE
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix
from sklearn.utils.class_weight import compute_class_weight
import tabnet

import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout, BatchNormalization, Input
from tensorflow.keras.utils import to_categorical
from tensorflow.keras.callbacks import EarlyStopping

# ==========================================
# PENGATURAN AWAL (SEED)
# ==========================================
np.random.seed(42)
tf.random.set_seed(42)

# ==========================================
# 1. INPUT DATASET
# ==========================================
print("1. Memuat dataset...")
df = pd.read_csv('ObesityDataSet_raw_and_data_sinthetic.csv')

# ==========================================
# 2. PREPROCESSING
# ==========================================
print("2. Melakukan Preprocessing...")

# a. Cek missing values
print("   -> Cek missing values per kolom:")
print(df.isnull().sum())

# b. Mengecek dan menghapus data yang duplikat
jumlah_duplikat = df.duplicated().sum()
if jumlah_duplikat > 0:
    df = df.drop_duplicates().reset_index(drop=True)
    print(f"   -> {jumlah_duplikat} baris duplikat telah dihapus.")

# c. Deteksi outlier pada kolom numerik menggunakan metode IQR
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

X = df.drop(columns=['NObeyesdad']).copy()
y = df['NObeyesdad']

# b. Encoding Fitur Kategorikal (Mengubah data teks menjadi angka)
cat_cols = X.select_dtypes(include=['object']).columns
for col in cat_cols:
    le = LabelEncoder()
    X[col] = le.fit_transform(X[col])

# c. Encoding Target Kategorikal
le_target = LabelEncoder()
y_encoded = le_target.fit_transform(y)
num_classes = len(le_target.classes_)

# ==========================================
# 3. TRANSFORMATION (Standardisasi Data)
# ==========================================
print("3. Melakukan Transformation (Scaling)...")
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# ==========================================
# 4. DATA SPLITTING (Train 80% : Val 10% : Test 10%)
# ==========================================
print("4. Melakukan Data Splitting...")
# Langkah 1: Pisahkan Data Testing (10%) dari sisa data
X_temp, X_test, y_temp, y_test = train_test_split(
    X_scaled, y_encoded, test_size=0.10, random_state=42, stratify=y_encoded
)

# Langkah 2: Pisahkan sisa 90% menjadi Training (80% total) dan Validation (10% total)
X_train, X_val, y_train, y_val = train_test_split(
    X_temp, y_temp, test_size=(1/9), random_state=42, stratify=y_temp
)

print(f"   -> Jumlah data Training   : {X_train.shape[0]}")
print(f"   -> Jumlah data Validation : {X_val.shape[0]}")
print(f"   -> Jumlah data Testing    : {X_test.shape[0]}")

# ==========================================
# 5. PENANGANAN IMBALANCED DATA
# ==========================================
print("5. Menangani Imbalanced Data (Kelas Tidak Seimbang)...")
print("\n   -> Distribusi kelas SEBELUM BorderlineSMOTE:")
unique_before, counts_before = np.unique(y_train, return_counts=True)
for cls_idx, cnt in zip(unique_before, counts_before):
    print(f"      Kelas '{le_target.classes_[cls_idx]}': {cnt} sampel")

# Cara 1: Menggunakan BorderlineSMOTE (Hanya untuk training set)
smote = BorderlineSMOTE(random_state=42)
X_resampled, y_resampled = smote.fit_resample(X_train, y_train)

print("   -> Distribusi kelas SESUDAH BorderlineSMOTE:")
unique_after, counts_after = np.unique(y_resampled, return_counts=True)
for cls_idx, cnt in zip(unique_after, counts_after):
    print(f"      Kelas '{le_target.classes_[cls_idx]}': {cnt} sampel")

# Cara 2: Menggunakan Class Weights
class_weights_array = compute_class_weight('balanced', classes=np.unique(y_train), y=y_train)
class_weights = dict(enumerate(class_weights_array))

y_train_cat = to_categorical(y_train, num_classes=num_classes)
y_resampled_cat = to_categorical(y_resampled, num_classes=num_classes)
y_val_cat = to_categorical(y_val, num_classes=num_classes)

# ==========================================
# 6. PEMBUATAN & PELATIHAN MODEL
# ==========================================
print("\n6. Membangun dan melatih model...")

early_stopping = EarlyStopping(
    monitor='val_loss', patience=15, restore_best_weights=True, verbose=0
)

def build_mlp():
    """Fungsi untuk membangun Arsitektur Model MLP (Multi-Layer Perceptron)"""
    model = Sequential([
        Input(shape=(X_train.shape[1],)),
        Dense(128, activation='relu'),
        BatchNormalization(),
        Dropout(0.3),
        Dense(64, activation='relu'),
        BatchNormalization(),
        Dropout(0.3),
        Dense(32, activation='relu'),
        BatchNormalization(),
        Dropout(0.2),
        Dense(num_classes, activation='softmax')
    ])
    model.compile(optimizer=tf.keras.optimizers.Adam(learning_rate=0.001), 
                  loss='categorical_crossentropy', metrics=['accuracy'])
    return model

def build_tabnet():
    """Fungsi untuk membangun Arsitektur Model TabNet"""
    model = tabnet.TabNetClassifier(
        num_classes=num_classes,
        feature_columns=None,
        num_features=X_train.shape[1],
        feature_dim=32,
        output_dim=16,
        num_decision_steps=4,
        relaxation_factor=1.5,
        sparsity_coefficient=1e-5
    )
    model.compile(optimizer=tf.keras.optimizers.Adam(learning_rate=0.01), 
                  loss='sparse_categorical_crossentropy', metrics=['accuracy'])
    return model

# --- 6a. Pelatihan MLP dengan SMOTE ---
print("   -> Training [1/4]: MLP + SMOTE...")
model_mlp_smote = build_mlp()
history_mlp_smote = model_mlp_smote.fit(
    X_resampled, y_resampled_cat, epochs=100, batch_size=32,
    validation_data=(X_val, y_val_cat), callbacks=[early_stopping], verbose=0
)

# --- 6b. Pelatihan MLP dengan Class Weight ---
print("   -> Training [2/4]: MLP + Class Weight...")
model_mlp_cw = build_mlp()
history_mlp_cw = model_mlp_cw.fit(
    X_train, y_train_cat, epochs=100, batch_size=32,
    validation_data=(X_val, y_val_cat), callbacks=[early_stopping], class_weight=class_weights, verbose=0
)

# --- 6c. Pelatihan TabNet dengan SMOTE ---
print("   -> Training [3/4]: TabNet + SMOTE...")
model_tabnet_smote = build_tabnet()
history_tabnet_smote = model_tabnet_smote.fit(
    X_resampled, y_resampled, epochs=100, batch_size=64,
    validation_data=(X_val, y_val), callbacks=[early_stopping], verbose=0
)

# --- 6d. Pelatihan TabNet dengan Class Weight ---
print("   -> Training [4/4]: TabNet + Class Weight...")
model_tabnet_cw = build_tabnet()
history_tabnet_cw = model_tabnet_cw.fit(
    X_train, y_train, epochs=100, batch_size=64,
    validation_data=(X_val, y_val), callbacks=[early_stopping], class_weight=class_weights, verbose=0
)

# ==========================================
# 7. EVALUASI MODEL
# ==========================================
print("\n7. Mengevaluasi Model pada Data Testing...")

def evaluate_model(model, X_test_data, y_test_data):
    """Fungsi untuk menghitung metrik evaluasi model (Accuracy, Precision, Recall, F1-Score)"""
    preds_prob = model.predict(X_test_data, verbose=0)
    preds = np.argmax(preds_prob, axis=1)
    
    acc = accuracy_score(y_test_data, preds)
    prec = precision_score(y_test_data, preds, average='weighted', zero_division=0)
    rec = recall_score(y_test_data, preds, average='weighted', zero_division=0)
    f1 = f1_score(y_test_data, preds, average='weighted', zero_division=0)
    
    return acc, prec, rec, f1, preds

# Menyimpan referensi model dan metrik
models_info = [
    ("MLP + SMOTE", model_mlp_smote),
    ("MLP + Class Weight", model_mlp_cw),
    ("TabNet + SMOTE", model_tabnet_smote),
    ("TabNet + Class Weight", model_tabnet_cw)
]

results = {}
predictions = {}

for name, model in models_info:
    acc, prec, rec, f1, preds = evaluate_model(model, X_test, y_test)
    results[name] = [acc, prec, rec, f1]
    predictions[name] = preds

# Cetak hasil ke terminal
print("\n=======================================================================")
print("                     HASIL KOMPARASI METRIK                            ")
print("=======================================================================")
print(f"{'Metode':<25} | Akurasi | Presisi | Recall  | F1-Score")
print("-" * 71)
for name, mets in results.items():
    print(f"{name:<25} | {mets[0]:.4f}  | {mets[1]:.4f}  | {mets[2]:.4f}  | {mets[3]:.4f}")
print("=======================================================================\n")

# Mencari model dengan F1-Score tertinggi
best_model_name = max(results, key=lambda k: results[k][3])
print(f"Model terbaik berdasarkan F1-Score adalah: {best_model_name}")

# ==========================================
# 8. VISUALISASI HASIL (Disimpan sebagai file .png)
# ==========================================
print("\n8. Menyiapkan dan menyimpan gambar visualisasi...")
plt.style.use('default')

# --- A. Grafik Training & Validation History (Loss dan Akurasi) ---
histories = {
    "MLP + SMOTE": history_mlp_smote,
    "MLP + Class Weight": history_mlp_cw,
    "TabNet + SMOTE": history_tabnet_smote,
    "TabNet + Class Weight": history_tabnet_cw
}

fig, axes = plt.subplots(4, 2, figsize=(15, 20))
fig.suptitle('Training and Validation Metrics per Model', fontsize=18, fontweight='bold', y=0.98)

for i, (name, history) in enumerate(histories.items()):
    hist_dict = history.history
    acc_key = [k for k in hist_dict.keys() if 'acc' in k and 'val' not in k][0]
    val_acc_key = 'val_' + acc_key
    
    # 1. Grafik Akurasi
    ax_acc = axes[i, 0]
    ax_acc.plot(hist_dict[acc_key], label='Training', color='blue', linewidth=2)
    ax_acc.plot(hist_dict[val_acc_key], label='Validation', color='orange', linewidth=2)
    ax_acc.set_title(f'{name} - Accuracy Gap', fontweight='bold')
    ax_acc.set_xlabel('Epochs')
    ax_acc.set_ylabel('Accuracy')
    ax_acc.legend()
    ax_acc.grid(True, linestyle='--', alpha=0.7)
    
    # 2. Grafik Loss
    ax_loss = axes[i, 1]
    ax_loss.plot(hist_dict['loss'], label='Training', color='blue', linewidth=2)
    ax_loss.plot(hist_dict['val_loss'], label='Validation', color='orange', linewidth=2)
    ax_loss.set_title(f'{name} - Loss Gap', fontweight='bold')
    ax_loss.set_xlabel('Epochs')
    ax_loss.set_ylabel('Loss')
    ax_loss.legend()
    ax_loss.grid(True, linestyle='--', alpha=0.7)

plt.tight_layout(rect=[0, 0, 1, 0.96])
plt.savefig('Training_Validation_History.png', dpi=300)
plt.close()

# --- B. Bar Chart Komparasi Metrik (Accuracy, Precision, dll) ---
labels = ['Accuracy', 'Precision', 'Recall', 'F1-Score']
x = np.arange(len(labels))
width = 0.2
fig, ax = plt.subplots(figsize=(10, 6))
colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728']

for i, (name, mets) in enumerate(results.items()):
    ax.bar(x + (i - 1.5) * width, mets, width, label=name, color=colors[i])

ax.set_ylabel('Scores')
ax.set_title('Perbandingan Metrik Evaluasi Keempat Model', fontweight='bold')
ax.set_xticks(x)
ax.set_xticklabels(labels)
ax.legend(loc='lower center', bbox_to_anchor=(0.5, -0.15), ncol=4)
ax.set_ylim(0, 1.1)
plt.tight_layout()
plt.savefig('Komparasi_Metrik_Evaluasi.png', dpi=300)
plt.close()

# --- C. Confusion Matrix (Prediksi Salah vs Benar) ---
fig, axes = plt.subplots(2, 2, figsize=(16, 12))
axes = axes.flatten()

for i, (name, mets) in enumerate(results.items()):
    cm = confusion_matrix(y_test, predictions[name])
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', ax=axes[i],
                xticklabels=le_target.classes_, yticklabels=le_target.classes_)
    axes[i].set_title(f'Confusion Matrix: {name}', fontweight='bold')
    axes[i].set_ylabel('Label Aktual')
    axes[i].set_xlabel('Label Prediksi')
    axes[i].set_xticklabels(axes[i].get_xticklabels(), rotation=45, ha='right')

plt.tight_layout()
plt.savefig('Confusion_Matrix_4Model.png', dpi=300)
plt.close()

# --- D. Bar Chart Distribusi Data Aktual vs Hasil Prediksi ---
actual_counts = pd.Series(y_test).value_counts().sort_index()
fig, ax = plt.subplots(figsize=(14, 7))
x_classes = np.arange(num_classes)
width_dist = 0.15

# Bar Aktual
ax.bar(x_classes - 2 * width_dist, actual_counts.values, width_dist, label='Data Aktual (Asli)', color='black', alpha=0.8)

# Bar Prediksi
for i, (name, preds) in enumerate(predictions.items()):
    pred_counts = pd.Series(preds).value_counts().reindex(x_classes, fill_value=0)
    ax.bar(x_classes + (i - 1) * width_dist, pred_counts.values, width_dist, label=f'Pred: {name}', color=colors[i])

ax.set_xlabel('Kategori / Kelas')
ax.set_ylabel('Jumlah Sampel')
ax.set_title('Distribusi Prediksi Tiap Kelas vs Data Aktual pada Testing Set', fontweight='bold')
ax.set_xticks(x_classes)
ax.set_xticklabels(le_target.classes_, rotation=45, ha='right')
ax.legend()
plt.tight_layout()
plt.savefig('Distribusi_Aktual_vs_Prediksi.png', dpi=300)
plt.close()

print("   -> Selesai! Semua grafik telah disimpan sebagai file PNG.")

# ==========================================
# 9. OUTPUT TERAKHIR: SIMPAN MODEL TERBAIK UNTUK GUI
# ==========================================
# Mengambil model berdasarkan nama dengan F1-Score tertinggi
best_model_idx = [n for n, m in models_info].index(best_model_name)
best_model = models_info[best_model_idx][1]

# Menghapus spasi dan plus agar nama file rapi (Contoh: "MLP + SMOTE" menjadi "mlp_smote")
safe_name = best_model_name.replace(' ', '').replace('+', '_').lower()

if "TabNet" in best_model_name:
    # TabNet Keras Model disimpan dalam format folder
    filename = f"model_obesitas_{safe_name}"
    best_model.save(filename)
    print(f"\n9. Selesai! Model terbaik (TabNet) telah disimpan pada folder '{filename}' untuk dipakai di GUI.")
else:
    # MLP (Keras biasa) disimpan dalam format .keras
    filename = f"model_obesitas_{safe_name}.keras"
    best_model.save(filename)
    print(f"\n9. Selesai! Model terbaik (MLP) telah disimpan sebagai file '{filename}' untuk dipakai di GUI.")