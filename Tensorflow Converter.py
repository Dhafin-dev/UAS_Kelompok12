import tensorflow as tf

# 1. Muat model Keras Anda
model = tf.keras.models.load_model('model_obesitas_cnn1d.keras')

# 2. Konversi ke TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# 3. Simpan file .tflite
with open('model_obesitas_cnn1d.tflite', 'wb') as f:
    f.write(tflite_model)