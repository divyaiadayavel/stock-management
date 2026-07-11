abstract class CashDrawerDataSource {
  List<int> getOpenDrawerBytes();
}

class CashDrawerDataSourceImpl implements CashDrawerDataSource {
  @override
  List<int> getOpenDrawerBytes() {
    return [27, 112, 0, 25, 250];
  }
}