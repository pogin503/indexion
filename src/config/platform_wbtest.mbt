///|
test "platform: detect_platform returns valid platform" {
  let platform = detect_platform()
  // Should return one of the valid platforms on any system
  assert_true(
    platform == MacOS ||
    platform == Linux ||
    platform == Windows ||
    platform == Unknown,
  )
}

///|
test "platform: get_global_config_dir returns path on supported platforms" {
  let platform = detect_platform()
  if platform != Unknown {
    let config_dir = get_global_config_dir()
    assert_true(config_dir is Some(_))
    let dir = config_dir.unwrap()
    assert_true(dir.contains("indexion") || dir.contains("Indexion"))
  }
}

///|
test "platform: get_global_data_dir returns path on supported platforms" {
  let platform = detect_platform()
  if platform != Unknown {
    let data_dir = get_global_data_dir()
    assert_true(data_dir is Some(_))
    let dir = data_dir.unwrap()
    assert_true(dir.contains("indexion") || dir.contains("Indexion"))
  }
}

///|
test "platform: get_global_cache_dir returns path on supported platforms" {
  let platform = detect_platform()
  if platform != Unknown {
    let cache_dir = get_global_cache_dir()
    assert_true(cache_dir is Some(_))
    let dir = cache_dir.unwrap()
    assert_true(dir.contains("indexion") || dir.contains("Indexion"))
  }
}

///|
test "platform: macOS paths follow Apple conventions" {
  let platform = detect_platform()
  if platform == MacOS {
    let config_dir = get_global_config_dir().unwrap()
    let data_dir = get_global_data_dir().unwrap()
    let cache_dir = get_global_cache_dir().unwrap()
    assert_true(config_dir.contains("/Library/Application Support/"))
    assert_true(data_dir.contains("/Library/Application Support/"))
    assert_true(cache_dir.contains("/Library/Caches/"))
  }
}

///|
test "platform: Linux paths follow XDG conventions" {
  let platform = detect_platform()
  if platform == Linux {
    let config_dir = get_global_config_dir().unwrap()
    let data_dir = get_global_data_dir().unwrap()
    let cache_dir = get_global_cache_dir().unwrap()
    // Should contain .config, .local/share, or .cache (XDG defaults)
    // or custom XDG paths
    assert_true(
      config_dir.contains("/.config/") || config_dir.contains("/indexion"),
    )
    assert_true(
      data_dir.contains("/.local/share/") || data_dir.contains("/indexion"),
    )
    assert_true(
      cache_dir.contains("/.cache/") || cache_dir.contains("/indexion"),
    )
  }
}
