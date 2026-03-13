/**
 * Simple calculator class used as an example for testing the Java LSP plugin.
 */
public class Calculator {

  /**
   * Adds two integers and returns the result.
   *
   * @param a the first integer
   * @param b the second integer
   * @return the sum of a and b
   */
  public int add(int a, int b) {
    return a + b;
  }

  public static void main(String[] args) {
    Calculator calc = new Calculator();
    System.out.println("2 + 3 = " + calc.add(2, 3));
  }
}
