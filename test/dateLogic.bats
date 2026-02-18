setup() {
    load 'common-setup'
    _common_setup
    # shellcheck disable=SC1091
    . "$PROJECT_ROOT/dateLogic.sh"
}

@test "calculateMostRecentSchedule daily same day" {
    run calculateMostRecentSchedule 11 0 "*" "$(rfc33382iso "2024-10-13 23:36:40-04:00")"
    assert_output "$(rfc33382iso "2024-10-13 11:00:00-04:00")"
}
@test "calculateMostRecentSchedule daily prev day" {
    run calculateMostRecentSchedule 12 0 "*" "$(rfc33382iso "2024-10-13 11:36:40-04:00")"
    assert_output "$(rfc33382iso "2024-10-12 12:00:00-04:00")"
}
