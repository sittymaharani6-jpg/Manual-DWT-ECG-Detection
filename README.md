# ECG PQRST Detection Using Manual Discrete Wavelet Transform

## Tentang Program

Program ini digunakan untuk mendeteksi gelombang P, Q, R, S, dan T pada sinyal ECG open source menggunakan metode Discrete Wavelet Transform atau DWT.

Proses utama yang dilakukan meliputi:

- membaca sinyal ECG;
- memilih lead yang akan dianalisis;
- preprocessing untuk mengurangi baseline wander;
- filtering menggunakan LPF dan HPF Daubechies;
- dekomposisi DWT secara manual sampai level 5;
- mendeteksi kompleks QRS dan posisi R;
- menentukan posisi Q, S, P, dan T;
- menampilkan hasil deteksi melalui GUI.

DWT dibuat secara manual sehingga proses filtering dan downsampling tidak menggunakan fungsi DWT bawaan.

Program juga tidak menggunakan:

```text
dwt()
wavedec()
wfilters()
findpeaks()
```

---

## Dataset

Data ECG menggunakan PTB Diagnostic ECG Database dari PhysioNet.

| Informasi | Keterangan |
|---|---|
| Dataset | PTB Diagnostic ECG Database |
| Record | patient001 / s0010_re |
| File utama | s0010_re.dat |
| Sampling frequency | 1000 Hz |
| Lead default | Lead I |
| Sumber | PhysioNet |

Program menyediakan pilihan lead:

```text
I
II
III
aVR
aVL
aVF
V1
V2
V3
V4
V5
V6
```

Lead dapat dipilih langsung melalui bagian `Lead` pada GUI.

Sumber dataset:

https://physionet.org/content/ptbdb/1.0.0/

---

## Tools

### MATLAB

Digunakan untuk:

- membaca data ECG;
- preprocessing sinyal;
- implementasi DWT manual;
- deteksi PQRST;
- visualisasi hasil;
- pembuatan GUI.

### MATLAB GUI

GUI dibuat menggunakan beberapa komponen seperti:

```text
uifigure
uipanel
uibutton
uidropdown
uiaxes
uitab
uitabgroup
```

GUI digunakan untuk mengatur data, lead, parameter deteksi, serta menampilkan hasil proses DWT dan PQRST.

### PhysioNet

Digunakan sebagai sumber sinyal ECG open source melalui PTB Diagnostic ECG Database.

---

## Referensi

Referensi utama yang digunakan:

B. Priyadarshini, R. K. Ranjan, dan Rajeev Arya.

Determining ECG Characteristics Using Wavelet Transforms.

International Journal of Engineering Research and Technology, Volume 1, Issue 6, 2012.

Paper tersebut membahas:

- penggunaan sinyal ECG dari PTB-DB;
- penggunaan wavelet Daubechies;
- dekomposisi wavelet untuk analisis ECG;
- deteksi karakteristik P, Q, R, S, dan T;
- penggunaan detail wavelet untuk membantu menemukan kompleks QRS.

Pada paper digunakan dekomposisi db2 hingga 8 level.

Pada program ini digunakan konsep yang sama sebagai referensi, tetapi dekomposisi dibuat manual sampai level 5.

---

## Wavelet

Wavelet yang digunakan adalah:

```text
Daubechies db2 / D4
```

Filter memiliki empat koefisien.

### Low Pass Filter

```matlab
h(1) = (1+sqrt(3))/(4*sqrt(2));
h(2) = (3+sqrt(3))/(4*sqrt(2));
h(3) = (3-sqrt(3))/(4*sqrt(2));
h(4) = (1-sqrt(3))/(4*sqrt(2));
```

### High Pass Filter

```matlab
g(1) = (1-sqrt(3))/(4*sqrt(2));
g(2) = -(3-sqrt(3))/(4*sqrt(2));
g(3) = (3+sqrt(3))/(4*sqrt(2));
g(4) = -(1+sqrt(3))/(4*sqrt(2));
```

LPF dan HPF ditulis langsung di dalam kode tanpa menggunakan `wfilters()`.

---

## Alur Program

Proses pada program dilakukan melalui beberapa tahap:

1. Membaca sinyal ECG open source dari file dataset.
2. Memilih lead ECG yang akan dianalisis.
3. Melakukan preprocessing untuk mengurangi baseline wander.
4. Memproses sinyal menggunakan Low Pass Filter dan High Pass Filter Daubechies yang ditulis secara manual.
5. Melakukan dekomposisi DWT dari level 1 sampai level 5.
6. Menggunakan detail DWT level 5 untuk mencari kandidat kompleks QRS.
7. Menentukan posisi R dari kandidat QRS.
8. Menentukan posisi Q dan S berdasarkan posisi R.
9. Menentukan posisi P dan T menggunakan window pencarian sebelum dan setelah kompleks QRS.
10. Menampilkan hasil deteksi P, Q, R, S, dan T melalui GUI.

---

## Preprocessing

Sinyal ECG terlebih dahulu diproses untuk mengurangi baseline wander.

Baseline dihitung menggunakan moving average.

```matlab
baseline = movingAverage(ecg,baseWin);

clean = ecg - baseline;
clean = clean - mean(clean);
```

Hasilnya digunakan sebagai sinyal input untuk proses DWT.

---

## DWT Manual

Pada setiap level, sinyal diproses menggunakan dua filter.

Low Pass Filter menghasilkan nilai approximation, sedangkan High Pass Filter menghasilkan nilai detail.

Setelah proses filtering, dilakukan downsampling dengan faktor 2. Approximation dari satu level digunakan kembali sebagai input untuk level berikutnya.

Urutan dekomposisi yang digunakan:

1. Level 1 menghasilkan A1 dan D1.
2. A1 digunakan sebagai input level 2 dan menghasilkan A2 serta D2.
3. A2 digunakan sebagai input level 3 dan menghasilkan A3 serta D3.
4. A3 digunakan sebagai input level 4 dan menghasilkan A4 serta D4.
5. A4 digunakan sebagai input level 5 dan menghasilkan A5 serta D5.

Bagian utama DWT manual:

```matlab
for n = 1:2:(length(x)-L+1)

    a = 0;
    d = 0;

    for k = 1:L
        a = a + x(n+k-1)*h(k);
        d = d + x(n+k-1)*g(k);
    end

    A(out) = a;
    D(out) = d;

    out = out + 1;
end

Perulangan dengan langkah `2` sekaligus melakukan proses downsampling dengan faktor 2.

Pada setiap level DWT, sinyal diproses menggunakan dua filter:

- Low Pass Filter menghasilkan komponen approximation.
- High Pass Filter menghasilkan komponen detail.

Approximation dari setiap level digunakan sebagai input untuk level berikutnya, sedangkan detail disimpan sebagai hasil dekomposisi pada level tersebut.

Urutan dekomposisi yang digunakan:

1. Level 1 menghasilkan A1 dan D1.
2. A1 digunakan sebagai input level 2 untuk menghasilkan A2 dan D2.
3. A2 digunakan sebagai input level 3 untuk menghasilkan A3 dan D3.
4. A3 digunakan sebagai input level 4 untuk menghasilkan A4 dan D4.
5. A4 digunakan sebagai input level 5 untuk menghasilkan A5 dan D5.

Pada program ini, detail level 5 atau D5 digunakan untuk membantu mencari kandidat kompleks QRS.

Bagian utama DWT manual:

```matlab
for n = 1:2:(length(x)-L+1)

    a = 0;
    d = 0;

    for k = 1:L
        a = a + x(n+k-1)*h(k);
        d = d + x(n+k-1)*g(k);
    end

    A(out) = a;
    D(out) = d;

    out = out + 1;
end
```

Perulangan dengan langkah `2` sekaligus melakukan proses downsampling.

---

## Deteksi R

Deteksi dimulai dari detail level 5.

```matlab
d5 = D{5};
score = abs(d5);
```

Threshold ditentukan menggunakan:

```matlab
threshold = mean(score) + std(score);
```

Proses deteksi R dilakukan dengan langkah berikut:

1. Mengambil detail DWT level 5.
2. Mengubah nilai D5 menjadi nilai absolut.
3. Menentukan threshold dari nilai rata-rata dan standar deviasi.
4. Mencari kandidat peak yang melewati threshold.
5. Mengembalikan posisi kandidat ke skala sinyal ECG.
6. Melakukan refinement pada sinyal ECG untuk menentukan posisi R.

---

## Deteksi Q dan S

Q dan S dicari setelah posisi R diketahui.

### Q

Q dicari sebagai nilai minimum pada area sebelum R.

```matlab
[~,loc] = min(clean(a:b));
Q(k) = a + loc - 1;
```

### S

S dicari sebagai nilai minimum pada area setelah R.

```matlab
[~,loc] = min(clean(a:b));
S(k) = a + loc - 1;
```

Batas pencarian Q dan S diatur melalui parameter `T1` dan `T2`.

---

## Deteksi P dan T

### P

P dicari pada window sebelum kompleks QRS.

```matlab
[~,loc] = max(clean(a:b));
P(k) = a + loc - 1;
```

Area pencarian P ditentukan menggunakan `T3` dan `T4`.

### T

T dicari pada window setelah kompleks QRS.

```matlab
[~,loc] = max(clean(a:b));
T(k) = a + loc - 1;
```

Area pencarian T ditentukan menggunakan `T5` dan `Delay1`.

---

## Parameter Deteksi

| Parameter | Fungsi |
|---|---|
| T1 | Batas pencarian Q sebelum R |
| T2 | Batas pencarian S setelah R |
| T3 | Awal pencarian P sebelum R |
| T4 | Akhir pencarian P sebelum R |
| T5 | Awal pencarian T setelah R |
| Delay1 | Akhir pencarian T |
| Delay2 | Jarak minimum antar R |
| Delay3 | Window baseline removal |
| Delay4 | Refinement R ke arah kiri |
| Delay5 | Refinement R ke arah kanan |

Parameter waktu menggunakan satuan milidetik.

---

## Visualisasi PQRST

Setelah posisi P, Q, R, S, dan T ditemukan, hasil dibuat dalam bentuk area atau pulse.

```matlab
gateP = pulseGate(P,N,round(0.025*fs),0.55);
gateQ = pulseGate(Q,N,round(0.012*fs),0.70);
gateR = pulseGate(R,N,round(0.012*fs),1.00);
gateS = pulseGate(S,N,round(0.012*fs),0.85);
gateT = pulseGate(T,N,round(0.030*fs),0.65);
```

Bentuk kotak menunjukkan area hasil deteksi.

Tinggi P, Q, R, S, dan T dibuat berbeda agar hasil lebih mudah dibedakan pada grafik.

Nilai tinggi tersebut hanya untuk visualisasi dan tidak menunjukkan amplitudo sebenarnya dari gelombang ECG.

---

## GUI

GUI terdiri dari beberapa bagian.

### Prosses

Menampilkan sinyal ECG yang sedang dianalisis.

### Filter Bank

Menampilkan:

- sinyal input;
- LPF `h[n]`;
- HPF `g[n]`;
- frequency response;
- detail DWT D1 sampai D5.

### Detection

Menampilkan sinyal ECG dan hasil deteksi:

```text
P
Q
R
S
T
```

Tampilan Detection dibuat lebih dekat pada satu beat agar posisi setiap gelombang lebih mudah dilihat.

### Mallat, Zero-cross, dan Gradient

Tab ini tersedia pada GUI sebagai bagian dari tampilan.

Pada implementasi saat ini, Zero-cross dan Gradient tidak digunakan dalam proses utama deteksi PQRST.

---

## Cara Menjalankan

File utama:

```text
EKG_DWT.m
```

Data yang digunakan:

```text
s0010_re.dat
s0010_re.hea
```

Jalankan program melalui MATLAB:

```matlab
EKG_DWT
```

Setelah GUI muncul:

1. Klik `Data`.
2. Pilih `s0010_re.dat`.
3. Pilih lead ECG yang ingin digunakan.
4. Atur jumlah data jika diperlukan.
5. Klik `Action`.
6. Buka tab `Detection` untuk melihat hasil PQRST.

---

## Output

Program menghasilkan:

| Output | Keterangan |
|---|---|
| ECG | Sinyal ECG yang dianalisis |
| LPF | Koefisien Low Pass Filter |
| HPF | Koefisien High Pass Filter |
| D1-D5 | Detail hasil dekomposisi DWT |
| R | Hasil deteksi R peak |
| Q dan S | Titik di sekitar kompleks QRS |
| P | Gelombang sebelum QRS |
| T | Gelombang setelah QRS |
| Detection | Visualisasi area PQRST |

---

## Catatan

Program menggunakan DWT manual sebagai dasar deteksi kompleks QRS.

Posisi R menjadi referensi utama untuk menentukan P, Q, S, dan T.

Parameter threshold dan window pencarian masih dapat dikembangkan agar lebih adaptif terhadap variasi sinyal ECG dan lead yang berbeda.

Program ini digunakan untuk analisis dan pembelajaran pemrosesan sinyal ECG, bukan untuk diagnosis medis.
