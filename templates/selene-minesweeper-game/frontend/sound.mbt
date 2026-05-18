///|
let sound_reveal : Ref[@host.Sound?] = { val: None }

///|
let sound_flag : Ref[@host.Sound?] = { val: None }

///|
let sound_explode : Ref[@host.Sound?] = { val: None }

///|
let sound_win : Ref[@host.Sound?] = { val: None }

///|
fn push_u16_le(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push((value & 0xFF).to_byte())
  bytes.push(((value >> 8) & 0xFF).to_byte())
}

///|
fn push_u8(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(value.to_byte())
}

///|
fn push_u32_le(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push((value & 0xFF).to_byte())
  bytes.push(((value >> 8) & 0xFF).to_byte())
  bytes.push(((value >> 16) & 0xFF).to_byte())
  bytes.push(((value >> 24) & 0xFF).to_byte())
}

///|
fn push_i16_le(bytes : Array[Byte], value : Int) -> Unit {
  let v = if value < 0 { value + 65536 } else { value }
  push_u16_le(bytes, v)
}

///|
fn synth_tone_wav_bytes(
  freq_hz : Double,
  seconds : Double,
  volume : Double,
) -> Bytes {
  let sample_rate = 22050
  let sample_count = (seconds * sample_rate.to_double()).to_int()
  let data_size = sample_count * 2
  let riff_size = 36 + data_size
  let bytes : Array[Byte] = []
  push_u8(bytes, 82)
  push_u8(bytes, 73)
  push_u8(bytes, 70)
  push_u8(bytes, 70)
  push_u32_le(bytes, riff_size)
  push_u8(bytes, 87)
  push_u8(bytes, 65)
  push_u8(bytes, 86)
  push_u8(bytes, 69)
  push_u8(bytes, 102)
  push_u8(bytes, 109)
  push_u8(bytes, 116)
  push_u8(bytes, 32)
  push_u32_le(bytes, 16)
  push_u16_le(bytes, 1)
  push_u16_le(bytes, 1)
  push_u32_le(bytes, sample_rate)
  push_u32_le(bytes, sample_rate * 2)
  push_u16_le(bytes, 2)
  push_u16_le(bytes, 16)
  push_u8(bytes, 100)
  push_u8(bytes, 97)
  push_u8(bytes, 116)
  push_u8(bytes, 97)
  push_u32_le(bytes, data_size)

  let amplitude = 32767.0 * volume
  for i in 0..<sample_count {
    let time = i.to_double() / sample_rate.to_double()
    let env = if time < 0.02 {
      time / 0.02
    } else if time > seconds - 0.05 {
      let tail = (seconds - time) / 0.05
      if tail > 0.0 {
        tail
      } else {
        0.0
      }
    } else {
      1.0
    }
    let sample = @cmath.sin(2.0 * 3.141592653589793 * freq_hz * time) *
      amplitude *
      env
    push_i16_le(bytes, sample.to_int())
  }
  Bytes::from_array(bytes)
}

///|
fn make_tone(
  freq_hz : Double,
  seconds : Double,
  volume : Double,
) -> @host.Sound {
  let wav_bytes = synth_tone_wav_bytes(freq_hz, seconds, volume)
  @host.sound_from_wav_bytes(wav_bytes)
}

///|
fn ensure_sounds_loaded() -> Unit {
  if sound_reveal.val is Some(_) {
    return
  }
  sound_reveal.val = Some(make_tone(620.0, 0.05, 0.24))
  sound_flag.val = Some(make_tone(860.0, 0.07, 0.28))
  sound_explode.val = Some(make_tone(180.0, 0.30, 0.42))
  sound_win.val = Some(make_tone(1040.0, 0.16, 0.30))
}

///|
fn play_sound_ref(sound : Ref[@host.Sound?]) -> Unit {
  match sound.val {
    Some(value) => @host.play_sound(value)
    None => ()
  }
}
