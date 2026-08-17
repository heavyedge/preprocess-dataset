if [ "${GITHUB_EVENT_NAME}" = "release" ]; then
    HEAVYEDGE_TEST_MODE=0 make -j "$MAKE_JOBS" datasets examples
else
    HEAVYEDGE_TEST_MODE=1 make -j "$MAKE_JOBS" datasets examples tests
fi
