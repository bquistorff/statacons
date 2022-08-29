# Note that timestamp-newer/make compares target vs source, whereas timestamp-changed doesn't look at target
# (just prev vs current of source)
# 'content-timestamp' = 'timestamp-changed' and 'content'

# 'make' and 'content'
def dependency_newer_then_content_changed(dependency, target, prev_ni, repo_node=None):
    return (dependency.changed_timestamp_newer(target, prev_ni, repo_node)
            and dependency.changed_content(target, prev_ni, repo_node))


# 'make' and 'content-timestamp'
def changed_timestamp_then_dependency_newer_then_content_content(dependency, target, prev_ni, repo_node=None):
    return (dependency.changed_timestamp_newer(target, prev_ni, repo_node)
            and dependency.changed_timestamp_then_content(target, prev_ni, repo_node))


decider_str_lookup = {'content-timestamp-newer': dependency_newer_then_content_changed,
                      'content-timestamp-newer-timestamp-changed': changed_timestamp_then_dependency_newer_then_content_content}  # noqa: E501
decider_str_lookup.update({k: k for k in ['MD5', 'content', 'MD5-timestamp', 
                                          'content-timestamp', 'timestamp-newer',  # type: ignore
                                          'make', 'timestamp-match']})
