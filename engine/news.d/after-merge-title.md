* The after-merge workflow reads the new version from `engine/DESCRIPTION`
  for its commit title, rather than from R's output, where the
  repository's renv start-up message had ended up (0.78.18's title).
