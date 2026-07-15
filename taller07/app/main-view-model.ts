import { Observable } from "@nativescript/core";

export class MainViewModel extends Observable {
  private _count = 0;

  get count(): number {
    return this._count;
  }

  set count(value: number) {
    this._count = value;
    this.notifyPropertyChange("count", value);
  }

  increment(): void {
    this.count += 1;
  }

  reset(): void {
    this.count = 0;
  }
}
