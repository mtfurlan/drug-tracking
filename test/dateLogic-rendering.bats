setup() {
    load 'common-setup'
    _common_setup
    # shellcheck disable=SC1091
    . "$PROJECT_ROOT/dateLogic.sh"
}

@test "renderTimeAgo minutes" {
    run renderTimeAgo 0 60
    assert_output "1 minutes ago"
}
@test "renderTimeAgo hours" {
    run renderTimeAgo 0 3660
    assert_output "1 hours 1 minutes ago"
}
@test "renderTimeAgo days" {
    run renderTimeAgo 0 $((60 * 60 * 24 + 3660))
    assert_output "1 days 1 hours 1 minutes ago"
}
@test "renderTimeAgo implicit now" {
    run renderTimeAgo $(($(date +%s) - 60))
    assert_output "1 minutes ago"
}
