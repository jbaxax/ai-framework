import { Routes } from '@angular/router';

export const routes: Routes = [
  { path: '', pathMatch: 'full', redirectTo: 'comprobantes' },
  {
    path: 'comprobantes',
    loadComponent: () => import('./invoices/invoice-list/invoice-list').then((m) => m.InvoiceList),
  },
];
