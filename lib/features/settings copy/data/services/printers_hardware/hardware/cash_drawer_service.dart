class CashDrawerService {
  const CashDrawerService();

  List<int> openDrawer() {
    return const [27, 112, 0, 25, 250];
  }

  bool supportsCashDrawer(bool capability) {
    return capability;
  }
}