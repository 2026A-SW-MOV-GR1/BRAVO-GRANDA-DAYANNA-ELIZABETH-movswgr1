import { ApplicationSettings, EventData, Page } from "@nativescript/core";
import { MainViewModel } from "./main-view-model";

const COUNTER_KEY = "counter_value";
const viewModel = new MainViewModel();

export function onPageLoaded(args: EventData): void {
  const page = args.object as Page;

  const savedValue = ApplicationSettings.getNumber(COUNTER_KEY, 0);
  viewModel.count = savedValue;
  page.bindingContext = viewModel;
}

export function onIncrementTap(): void {
  viewModel.increment();
  ApplicationSettings.setNumber(COUNTER_KEY, viewModel.count);
  console.log(`[Lifecycle] Counter incremented to ${viewModel.count}`);
}

export function onResetTap(): void {
  viewModel.reset();
  ApplicationSettings.setNumber(COUNTER_KEY, viewModel.count);
  console.log(`[Lifecycle] Counter reset to ${viewModel.count}`);
}
