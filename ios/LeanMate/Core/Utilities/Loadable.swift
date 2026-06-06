enum Loadable<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(AppError)

    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
}
